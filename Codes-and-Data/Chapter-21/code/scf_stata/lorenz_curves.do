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

global tabdir = "${master2}tables/"
global figdir = "${master2}figures/"
global qrdata = "${master2}data/"

/* Put here CPI of base year and base year. The CPI of the base year can be read 
   off the denominator of the "cpiadj" factor below. */
//global basecpi = 3208 
//global baseyear = 2010
global basecpi = 4376
global baseyear = 2022


**# Lorenz Curves over time 

* Define Variables 
local varlist = "income networth"

* Define Years
* Note: If you change years, change legend entries below accordingly 
numlist "1989 2001 2010 2022"
local years "`r(numlist)'"

* Load in data 
foreach y in `years'{	
	/* Use data from main analysis */
	append using "${qrdata}qr5data`y'.dta"
	}
gen fwt = round(wgt1 * 100000000) // Generate frequency weights (lorenz does not allow to use analystic weights, only frequency weights (similar to aw) which have to be integers)


* Lorenz Curves
local i = 1
foreach var of varlist `varlist'{
	if "`var'" == "income"{
	    local ytitle "Income share"
	}
	else{
	    local ytitle "Wealth share"
	}
	lorenz `var' [fw=fwt], gini percent over(year)
	lorenz graph, overl legend(pos(6) rows(1)) xtitle("Population Share") ytitle("`ytitle'") name("Lorenz_`i'", replace)
	graph export "${figdir}lorenz_curve_over_time_`var'.eps", as(eps) replace
	local ++i
}


**# Lorenz Curves in baseyear 

use "${qrdata}qr5data${baseyear}", clear
gen fwt = round(wgt1 * 100000000)

* Wealth & housing Lorenz Curve
foreach var of varlist networth houses{
	if "`var'" == "houses"{
	   local ytitle "Housing Share"
	}
	else{
	   local ytitle "Wealth Share"
	}
	lorenz `var' [fw=fwt], gini percent
	lorenz graph, legend(off) xtitle("Population Share") ytitle("`ytitle'") name("Lorenz_`i'", replace)
	graph export "${figdir}lorenz_curve_`var'.eps", replace
	local ++i
}

* Lorenz curve of housing by wealth
sort networth earnings income, stable 
gen swgt = sum(wgt1)
sum swgt
qui replace swgt = 100 * (swgt / r(max))
qui sum houses [aw=wgt1]
gen shshare = 100 * sum((wgt1 * houses)/r(sum))
qui integ shshare swgt
local gini = round((.5 * 10000 -r(integral))/ (.5 * 10000),0.01)
di "Gini = " `gini'
local gini : display %3.2g `gini'
twoway (line shshare swgt) (line swgt swgt, col(black) lpattern(dash)), legend(off) xtitle("Population Share") ytitle("Housing Share") subtitle("Gini =`gini'") name("Lorenz_`i'", replace)
graph export "${figdir}_lorenz_curve_housing_nw.eps", replace
