*** Wealth to income ratios ***
clear all
set more off
set mem 1000m
set maxvar 10000
set trace off
pause off

global master1 = "/Users/niklashein/Desktop/Work/Uni_MA/Kuhn_RA/scf_update/" // Drive/Partition 1
global master2 = "/Users/niklashein/Desktop/Work/Uni_MA/Kuhn_RA/scf_update/" // Drive/Partition 2

net set ado /Users/niklashein/Desktop/Work/Uni_MA/Kuhn_RA/ado
sysdir set PLUS /Users/niklashein/Desktop/Work/Uni_MA/Kuhn_RA/ado
global af /Users/niklashein/Desktop/Work/Uni_MA/Kuhn_RA/ancillary_files

global dodir = "${master1}dofiles/"
global resdir = "${master1}results/"
global tabdir = "${master2}tables/"
global figdir = "${master2}figures/"
global data = "${master2}data/"
global wir = 27 // put here number of figure drawn below

global minyear = 1989
global maxyear = 2022 // if you change maxyear, you have to adjust cellrange below
global inyear = 10 // put here the SCF wave to which prices are indexed (10 = 2016)

global baseyear = 2022 
global basecpi = 4315 //average annual cpi from R-CPI-U-RS Series


**# Load in data 

**## SCF wealth to income ratio
local Y = ($maxyear - $minyear + 3) / 3  
matrix wir = J(`Y',2,.)
local i = 1
forvalues y = $minyear(3)$maxyear{
	matrix wir[`i',1] = `y'
	use "${data}qr5data`y'.dta", clear 
	qui sum networth [aw=wgt1]
	matrix wir[`i',2] = r(mean)
	qui sum income [aw=wgt1] 
	matrix wir[`i',2] = wir[`i',2] / r(mean)
	local ++i
}

**## Wealth to income ratio from Financial Accounts and NIPA
/* Data Source: 
Net Worth: Financial Accounts. B.101.h Balance Sheet of Households. Annual. Available at: https://fred.stlouisfed.org/series/BOGZ1FL192090005A
Income: NIPA. Table 2.6 Personal Income and Its Dispositionhttps. Annual. Available at: https://fred.stlouisfed.org/release/tables?rid=54&eid=155443#snid=155444 
Note: Following Kuhn et al. (2020), the following income components of the NIPA are included: wages and salaries, proprietors' income, rental income, personal income receipts, social security, unemployment insurance, veterans' benefits, other transfers, and other net current transfer receipts from a business.*/

* Net worth
import excel "${data}BOGZ1FL192090005A", sheet("Annual") firstrow cellrange(B1) clear
qui replace BOGZ1FL192090005A = BOGZ1FL192090005A * 1000000 // data are in millions of USD
mkmat BOGZ1FL192090005A, matrix(fa_w_all)
* Keep only years of SCF waves
local r = rowsof(fa_w_all)
matrix fa_w = fa_w_all[1,1...]
forvalues i = 4(3)`r'{
	matrix fa_w = fa_w \ fa_w_all[`i',1...]
}

* Income
import excel "${data}A576RC1_A041RC1_A048RC1_PIROA_W823RC1_W825RC1_W826RC1_W827RC1_B931RC1",  sheet("Annual") firstrow cellrange(B1) clear
qui replace A576RC1_A041RC1_A048RC1_PIROA_W8 = A576RC1_A041RC1_A048RC1_PIROA_W8 * 1000000000 // data are in billions of USD
mkmat A576RC1_A041RC1_A048RC1_PIROA_W8, matrix(nipa_i_all)
* Keep only years of SCF waves
local r = rowsof(nipa_i_all)
matrix nipa_i = nipa_i_all[1,1...]
forvalues i = 4(3)`r'{
	matrix nipa_i = nipa_i \ nipa_i_all[`i',1...]
}

* Ratios
mata 
a = st_matrix("fa_w")
b = st_matrix("nipa_i")
c = a :/ b
st_matrix("wir_fn",c)
end

**## Reproducible capital to GDP ratio
/* Data Sources:
GDP: Penn World Table 10.01. Real GDP at Constant National Prices for United States. Annual. Available at: https://fred.stlouisfed.org/series/RGDPNAUSA666NRUG
Reproducible capital: Penn World Table 10.01. Capital Stock at Constant National Prices for United States. Annual. Available at: https://fred.stlouisfed.org/series/RKNANPUSA666NRUG */

* GDP 
import excel "${data}RGDPNAUSA666NRUG", sheet("Annual") firstrow cellrange(B1) clear
qui replace RGDPNAUSA666NRUG = RGDPNAUSA666NRUG * 1000000 // data are in millions of USD
mkmat RGDPNAUSA666NRUG, matrix(gdp_all)
* Keep only years of SCF waves
local r = rowsof(gdp_all)
matrix gdp = gdp_all[1,1...]
forvalues i = 4(3)`r'{
	matrix gdp = gdp \ gdp_all[`i',1...]
}

* Capital 
import excel "${data}RKNANPUSA666NRUG", sheet("Annual") firstrow cellrange(B1) clear
qui replace RKNANPUSA666NRUG = RKNANPUSA666NRUG * 1000000 // data are in millions of USD
mkmat RKNANPUSA666NRUG, matrix(capital_all)
* Keep only years of SCF waves
local r = rowsof(capital_all)
matrix capital = capital_all[1,1...]
forvalues i = 4(3)`r'{
	matrix capital = capital \ capital_all[`i',1...]
}

* Ratios
mata 
a = st_matrix("gdp")
b = st_matrix("capital")
c = b :/ a
c = c \ (.) // cgdpr only goes through 2019
st_matrix("cgdpr",c)
end

matrix wcir = wir , wir_fn , cgdpr 
matrix colnames wcir = "year" "scf" "fn" "cgdp"


**# Draw graphs 
putexcel set "${resdir}figure${wir}", sheet("Wealth to income Ratios", replace) replace 
putexcel A1 = matrix(wcir), colnames 

svmat wcir, names(col)
twoway (connect scf year, msymbol(o) msize(medium)) (connect fn year, msymbol(S) msize(small)) (connect cgdp year, msymbol(D) msize(small)), ///
legend(label(1 "Wealth-to-Income Ratio (SCF)") label(2 "Wealth-to-Income Ratio (FA & NIPA)") label(3 "Capital-to-GDP Ratio") position(6) rows(2)) xtitle("Year") xlabel(1989(3)2022) name("asset_prices", replace) 
graph export "${figdir}wealth_income_ratios.eps", replace 
