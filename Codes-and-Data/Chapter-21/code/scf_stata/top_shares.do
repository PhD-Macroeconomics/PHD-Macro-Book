*** Top shares including the Forbes 400 List ***
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
global qrdata = "${master2}data/"

global baseyear = 2022 
global basecpi = 4376

global minyear = 1989
global maxyear = 2022
global numyear = 12 // put here number of waves between minyear and maxyear
global inyear = 10 // put here the SCF wave number relative to which growth rates of portfolio components are calculated (10 = 2001 - 5th wave of modern SCF)

* Globals for table formatting
global basefont = "basefont(rm small)"  //  base font for all text (rm = Roman, small = smaller than default font size)
global titlfont = "titlfont(large)" // font for table title (large = bigger than default font size, normalsize = default font size)
global coljust = "coljust(l{c}c)" // specifies whether the table columns are left, center, or right justified (l{c}c = all columns are center justified, except the first, which is left justified)
global format = "sfmt(g) sdec(0)" // numerical format for statistics (option sfmt(g) together with sdec(0) sets format to %8.0g)
global rtitles = `"rtitles("1989"\"1992"\"1995"\"1998"\"2001"\"2004"\"2007"\"2010"\"2013"\"2016"\"2019"\"2022")"'
global ts = 23 // Version 1: put here number of table for top shares written below
global pa = $ts + 1 // Version 1: number of table for portfolio changes written below 
global ps = $ts + 2 // Version 2: put here number of table for portfolio shares (table for levels/growth rates will be ps+1/ps+2)
global ol = $ts + 5 // put here number of table for overlap between top of distributions
global mm = $ts + 6 // put here number of table for overlap between top of distributions


**# Top wealth shares

**## Store average net worth by year of the Forbes 400 List in a matrix
* Sources: 1989-2016: https://www.sciencedirect.com/science/article/pii/S0165176516305262, 2019-2022: https://link.springer.com/article/10.1007/s40300-024-00267-6#appendices
matrix forbes = (1989,0.826\1992,0.897\1995,1.033\1998,1.754\2001,2.994\2004,2.505\2007,3.85\2010,3.366\2013,4.85\2016,5.946\2019,7.388\2022,10.012)

**## Calculate top shares 
matrix top_shares_networth = J(${numyear},10,.)
matrix colnames top_shares_networth = "year" "top_10" "top_10_forbes" "top_5" "top_5_forbes" "top_1" "top_1_forbes" "top_01" "top_01_forbes" "forbes"
matrix top_shares_income = J(${numyear},5,.)
matrix colnames top_shares_income = "year" "top_10" "top_5" "top_1" "top_01"  
matrix top_shares_earnings = J(${numyear},5,.)
matrix colnames top_shares_earnings = "year" "top_10" "top_5" "top_1" "top_01"
local i = 1
forvalues y = $minyear(3)$maxyear{
	if `y' == 1989{
		global cpiadj = ${basecpi}/1902 
	}
	else if `y' == 1992{
		global cpiadj = ${basecpi}/2116 
	}
	else if `y' == 1995{
		global cpiadj = ${basecpi}/2265 
	}
	else if `y' == 1998{
		global cpiadj = ${basecpi}/2405 
	}
	else if `y' == 2001{
		global cpiadj = ${basecpi}/2618 
	}
	else if `y' == 2004{
		global cpiadj = ${basecpi}/2788 
	}
	else if `y' == 2007{
		global cpiadj = ${basecpi}/3062 
	}
	else if `y' == 2010{
		global cpiadj = ${basecpi}/3208 
	}
	else if `y' == 2013{
		global cpiadj = ${basecpi}/3438 
	}
	else if `y' == 2016{
        global cpiadj = ${basecpi}/3547
	}
	else if `y' == 2019{
    	global cpiadj = ${basecpi}/3781
	}
    else if `y' == 2022{
    	global cpiadj = ${basecpi}/4376
	}
	use "${qrdata}qr5data`y'.dta", clear 
   	foreach var of varlist networth income earnings{
	    matrix top_shares_`var'[`i',1] = `y'
	    if "`var'" == "networth"{
		    forvalues k = 0/1{
		        if `k' == 0{ // SCF sample
		           local j = 2
				   qui sum networth [aw=wgt1]
	               local totalnw = r(sum)
		        }
		        else{ // SCF sample plus Forbes 400™
			      local j = 3
			      drop sumwgt totalwgt top*
			      local N = _N + 1
			      set obs `N'
			      replace wgt1 = 400 in `N'
			      replace networth = forbes[`i',2] * $cpiadj * 1000000000 in `N' // data are in billions of current USD 
				  qui sum networth [aw=wgt1]
				  local totalnw = r(sum)
				  matrix top_shares_networth[`i',10] = round(((networth[`N'] * wgt1[`N'])/`totalnw')*100,0.1)
		       }
	           sort networth earnings income, stable 
	           gen sumwgt = sum(wgt1)
	           egen totalwgt = max(sumwgt)
	           gen top10 = (sumwgt > .9 * totalwgt)
	           gen top5 = (sumwgt > .95 * totalwgt)
	           gen top1 = (sumwgt > .99 * totalwgt)
       	       gen top01 = (sumwgt > .999 * totalwgt)
	           foreach t in "10" "5" "1" "01"{
	              qui sum networth [aw=wgt1] if top`t' == 1 
		          matrix top_shares_networth[`i',`j'] = round((r(sum)/`totalnw')*100,0.1)
		          local j = `j' + 2
	           }
           }
		   drop if id == . // drop Forbes list
       }
	   else{
	   	   qui sum `var' [aw=wgt1]
	       local total`var' = r(sum)
	       if "`var'" == "income"{
		   	  sort income earnings networth, stable 
		   }
		   else{
		   	  sort earnings income networth, stable
		   }
	       gen sumwgt = sum(wgt1)
	       egen totalwgt = max(sumwgt)
	       gen top10 = (sumwgt > .9 * totalwgt)
	       gen top5 = (sumwgt > .95 * totalwgt)
	       gen top1 = (sumwgt > .99 * totalwgt)
       	   gen top01 = (sumwgt > .999 * totalwgt)
		   local j = 2
	       foreach t in "10" "5" "1" "01"{
	           qui sum `var' [aw=wgt1] if top`t' == 1 
		       matrix top_shares_`var'[`i',`j'] = round((r(sum)/`total`var'')*100,0.1)
		       local ++j
	       }

	   }
	   drop sumwgt totalwgt top*
   }
   local ++i
}

**## Write table 

**### Including Earnings and Income (excluding Forbes shares)
/*
* Earnings
matrix top_shares = top_shares_earnings[1...,2...]
frmttable, statmat(top_shares) tex $basefont $titlfont replace $coljust $rtitles title("Changes in Top Shares") $format ctitles("","\textbf{Earnings}","","",""\"","Top 10\%","Top 5\%","Top 1\%" ///
,"Top 0.1\%"\"","","","","") nodisplay
putexcel set "${resdir}table${ts}", sheet("Earnings", replace) replace 
putexcel A1 = matrix(top_shares_earnings), colnames 
* Income
matrix top_shares = top_shares_income[1...,2...]
frmttable, statmat(top_shares) tex $basefont $titlfont replace $coljust $format ctitles("\textbf{Income}","","",""\"Top 10\%","Top 5\%","Top 1\%" ///
,"Top 0.1\%"\"","","","") nodisplay merge 
putexcel set "${resdir}table${ts}", sheet("Income", replace) modify 
putexcel A1 = matrix(top_shares_income), colnames 
* Wealth
matrix top_shares = top_shares_networth[1...,2..9]
frmttable using "${tabdir}table$ts", statmat(top_shares) tex $basefont $titlfont replace $coljust multicol(1,2,4;1,6,4;1,10,8;2,10,2;2,12,2;2,14,2;2,16,2) $format ///
ctitles("\textbf{Wealth}","","","","","","",""\"Top 10\%","","Top 5\%","","Top 1\%","","Top 0.1\%",""\"w/o F400","w/ F400","w/o F400","w/ F400","w/o F400","w/ F400" ///
,"w/o F400","w/ F400") merge vlines(0100010001{0})
putexcel set "${resdir}table${ts}", sheet("Wealth", replace) modify 
putexcel A1 = matrix(top_shares_networth), colnames 
*/

**### Only top 1% and 0.1% wealth shares (including Forbes shares)
matrix top_shares = top_shares_networth[1...,6...]
frmttable using "${tabdir}table$ts", statmat(top_shares) tex $basefont $titlfont replace $coljust multicol(1,2,2;1,4,2) $format $rtitles ctitles("","\textbf{Top 1\%}","","\textbf{Top 0.1\%}","","\textbf{Forbes 400}"\ ///
"","w/o Forbes 400","w/ Forbes 400","w/o Forbes 400","w/ Forbes 400","") vlines(0101010)
putexcel set "${resdir}table${ts}", sheet("Wealth", replace) replace
matrix top_shares = top_shares_networth[1...,1] , top_shares_networth[1...,6...]
putexcel A1 = matrix(top_shares), colnames 

**## Draw graph 

**### Bar chart 
clear 
svmat top_shares_networth, names(col)
keep if year == $maxyear
drop top_10* top_01* forbes year 
set obs 2 
gen top = "Top 5%"
replace top = "Top 1%" in 2
gen scf = top_5
replace scf = top_1[1] in 2
gen forbes = top_5_forbes
replace forbes = top_1_forbes[1] in 2
keep top scf forbes 
graph bar scf forbes, over(top, sort(1) descending) legend(pos(6) label(1 "w/o Forbes 400 List") label(2 "w/ Forbes 400 List") rows(1)) ytitle("Share (%)") 
graph export "${figdir}topshares_bar.eps", as(eps) replace

**### Time series 
clear 
svmat top_shares_networth, names(col)
keep top_1_forbes top_1 forbes year
twoway (connect top_1 year, msymbol(o) msize(vlarge) col(stblue) yaxis(1)) (connect top_1_forbes year, msymbol(o) msize(vlarge) col(stblue) lpattern(dash) yaxis(1)) ///
(connect forbes year, msymbol(S) msize(medium) col(stred) yaxis(2)), legend(label(1 "Top 1% (w/o Forbes 400)") label(2 "Top 1% (w/ Forbes 400)") label(3 "Forbes 400") pos(6) rows(1)) ///
xtitle("Year") ytitle("Top 1%", axis(1)) ytitle("Forbes 400", axis(2)) xlabel(1989(3)2022)
graph export "${figdir}topshares_timeseries.eps", as(eps) replace

**# Portfolio analysis 

**## Version 1 
/*
matrix portfolio_changes_top_1 = J(6,5,.)
matrix colnames portfolio_changes_top_1 = "share19" "level19" "share22" "level22" "growth"
matrix rownames portfolio_changes_top_1 = "housing_cars" "business_nfinancial" "financial" "coldebt" "ncoldebt" "total"
matrix portfolio_changes_bottom_99 = J(6,5,.)
matrix colnames portfolio_changes_bottom_99 = "share19" "level19" "share22" "level22" "growth"
matrix rownames portfolio_changes_bottom_99 = "housing_cars" "business_nfinancial" "financial" "coldebt" "ncoldebt" "total"
local i = 1
forvalues y = 2019(3)2022{
   	use "${qrdata}qr5data`y'.dta", clear 
	sort networth earnings income, stable 
	gen sumwgt = sum(wgt1)
	egen totalwgt = max(sumwgt)
    gen top1 = (sumwgt > .99 * totalwgt)
    forvalues t = 0/1{
		if `t' == 0{
			local group "bottom_99"
		}
		else{
			local group "top_1"
		}
		qui sum networth [aw=wgt1] if top1 == `t'
		local sum_nw = r(sum)
		local j = 1
		foreach var of varlist housecars businessnonfin financialassets colldebt nocolldebt{
			qui sum `var' [aw=wgt1] if top1 == `t'
			matrix portfolio_changes_`group'[`j',`i'] = round((r(sum)/`sum_nw')*100,0.1)
			matrix portfolio_changes_`group'[`j',`i'+1] = round(r(sum)/1000000,0.1)
			if `y' == 2022{
				matrix portfolio_changes_`group'[`j',5] = round(100* (portfolio_changes_`group'[`j',4]- portfolio_changes_`group'[`j',2]) / portfolio_changes_`group'[`j',2],0.1)
			}
			local ++j
		}
		matrix portfolio_changes_`group'[6,`i'] = 100
		matrix portfolio_changes_`group'[6,`i'+1] = round(`sum_nw'/1000000,0.1)
		if `y' == 2022{
			matrix portfolio_changes_`group'[6,5] = round(100* (portfolio_changes_`group'[6,4]- portfolio_changes_`group'[6,2]) / portfolio_changes_`group'[6,2],0.1)
		}
	}
	local i = `i' + 2
}
frmttable, statmat(portfolio_changes_bottom_99) tex $basefont $titlfont replace $coljust title("Portfolio Changes: Bottom 99\% vs. Top 1\%") $format ctitles("","\textbf{Bottom 99\%}","","","",""\"","2019","" ///
,"2022","","Growth Rate (\%)"\"","Share (\%)","Level (x$10^6$)","Share (\%)","Level (x$10^6$)","Level") rtitles("Housing \& Cars"\"Business \& Nonfinancial"\"Financial Assets"\"Collaterized Debt" ///
\"Uncollaterized Debt"\"Total") nodisplay

frmttable using "${tabdir}table$pa", statmat(portfolio_changes_top_1) tex $basefont $titlfont replace $coljust $format ctitles("","\textbf{Top 1\%}","","","",""\"","2019","" ///
,"2022","","Growth Rate (\%)"\"","Share (\%)","Level (x$10^6$)","Share (\%)","Level (x$10^6$)","Level") rtitles("Housing \& Cars"\"Business \& Nonfinancial"\"Financial Assets"\"Collaterized Debt" ///
\"Uncollaterized Debt"\"Total") multicol(1,2,5;1,7,5;2,2,2;2,4,2;2,7,2;2,9,2) vlines(0100001{0}) merge
*/

**## Version 2

* Calculate statistics
forvalues i = 1/4{
	forvalues j = 1/3{
		if `j' == 1{
			local quant "share"
		} 
		else if `j' == 2{
			local quant "level"
		}
		else if `j' == 3{
			local quant "growth"
		}
	    matrix portfolio_changes_`i'_`j' = J(${numyear},11,.)
        matrix colnames portfolio_changes_`i'_`j' = "year" "houses_`quant'" "homeequity`quant'" "business_`quant'" "retireliquidassets_`quant'" "financialassets2_`quant'" "assets_rest_`quant'" ///
		"mrthel_`quant'" "debt_rest_`quant'" "colldebt_`quant'" "nocolldebt_`quant'"
	}
}
local k = 1
forvalues y = $minyear(3)$maxyear{
	use "${qrdata}qr5data`y'.dta", clear 
	gen financialassets2 = stocks + bonds + mutualfunds
	gen assets_rest = assets-(houses+business+retireliquidassets+stocks+bonds+mutualfunds)
	gen debt_rest = - (debt - mrthel)
    qui replace mrthel = - mrthel
	sort networth earnings income, stable 
	gen sumwgt = sum(wgt1)
	egen totalwgt = max(sumwgt)
    gen wealthgroup = 1 + (sumwgt > .5 * totalwgt) + (sumwgt > .9 * totalwgt) + (sumwgt > .99 * totalwgt)
	forvalues i = 1/4{
		forvalues j = 1/3{
			matrix portfolio_changes_`i'_`j'[`k',1] = `y'
		}
		qui sum networth [aw=wgt1] if wealthgroup == `i'
		local totalnw = r(sum)
		local l = 2
		foreach var of varlist houses homeequity business retireliquidassets financialassets2 assets_rest mrthel debt_rest colldebt nocolldebt{
			qui sum `var' [aw=wgt1] if wealthgroup == `i'
			matrix portfolio_changes_`i'_1[`k',`l'] = round(100*(r(sum)/`totalnw'),0.1)
			matrix portfolio_changes_`i'_2[`k',`l'] = round(r(mean)/1000,0.1)
			matrix portfolio_changes_`i'_3[`k',`l'] = r(sum)
			if `y' == $maxyear{
				local binyear = ${inyear} - 1
				local ainyear = ${inyear} + 1
				forvalues t = 1/`binyear'{
					matrix portfolio_changes_`i'_3[`t',`l'] = round(100 * ((portfolio_changes_`i'_3[`t',`l'] - portfolio_changes_`i'_3[${inyear},`l'])/portfolio_changes_`i'_3[${inyear},`l']),0.1)
				}
				forvalues t = `ainyear'/$numyear{
				    matrix portfolio_changes_`i'_3[`t',`l'] = round(100 * ((portfolio_changes_`i'_3[`t',`l'] - portfolio_changes_`i'_3[${inyear},`l'])/portfolio_changes_`i'_3[${inyear},`l']),0.1)
				}
			    matrix portfolio_changes_`i'_3[${inyear},`l'] = 0
			}
			local ++l
		}
	}
	local ++k
}

* Write tables 
local ps = $ps
forvalues j = 1/3{
	if `j' == 1{
		local title "Portfolio Components by SCF Wave and Wealth Group: Shares (\%)"
	}
	else if `j' == 2{
		local title "Portfolio Components by SCF Wave and Wealth Group: Levels (x $10^3$ USD)"
	}
	else{
		local title "Portfolio Components by SCF Wave and Wealth Group: Growth Rates Relative to 2001 (\%)"
	}
	* Base tables
	matrix portfolio_changes = portfolio_changes_1_`j'[1...,2] , portfolio_changes_1_`j'[1...,4..9] , portfolio_changes_2_`j'[1...,2] , portfolio_changes_2_`j'[1...,4..9]
	frmttable using "${tabdir}table`ps'", statmat(portfolio_changes) tex $basefont $titlfont replace $coljust title("`title' \bigskip" \ "(a): Bottom 90\%") $format $rtitles ///
	ctitles("","\textbf{Bottom 50\%}","","","","","","","\textbf{50\% - 90\%}","","","","","",""\"","Housing","Business","Ret. Accts.","Fin. Assets$^a$","Other Assets","Housing Debt","Other Debt", ///
	"Housing","Business","Ret. Accts.","Fin. Assets$^a$","Other Assets","Housing Debt","Other Debt") vlines(01000010100001{0}) multicol(1,2,7;1,9,7)
	matrix portfolio_changes = portfolio_changes_3_`j'[1...,2] , portfolio_changes_3_`j'[1...,4..9] , portfolio_changes_4_`j'[1...,2] , portfolio_changes_4_`j'[1...,4..9]
	frmttable using "${tabdir}table`ps'", statmat(portfolio_changes) tex $basefont $titlfont replace $coljust title("(b): Top 10\%") $format $rtitles ///
	ctitles("","\textbf{90\% - 99\%}","","","","","","","\textbf{Top 1\%}","","","","","",""\"","Housing","Business","Ret. Accts.","Fin. Assets$^a$","Other Assets","Housing Debt","Other Debt", ///
	"Housing","Business","Ret. Accts.","Fin. Assets$^a$","Other Assets","Housing Debt","Other Debt") vlines(01000010100001{0}) multicol(1,2,7;1,9,7) addtable
	* Extended tables
	matrix portfolio_changes = portfolio_changes_1_`j'[1...,2..11] , portfolio_changes_2_`j'[1...,2..11] 
	frmttable using "${tabdir}table`ps'_e", statmat(portfolio_changes) tex $basefont $titlfont replace $coljust title("`title' \bigskip" \ "(a): Bottom 90\%") $format $rtitles ///
	ctitles("","\textbf{Bottom 50\%}","","","","","","","","","","\textbf{50\% - 90\%}","","","","","","","","",""\"","Housing","Home Equity","Business","Ret. Accts.","Fin. Assets$^a$","Other Assets","Housing Debt" ///
	,"Nonhousing Debt","Collaterized Debt","Uncollaterized Debt","Housing","Home Equity","Business","Ret. Accts.","Fin. Assets$^a$","Other Assets","Housing Debt","Nonhousing Debt","Collaterized Debt","Uncollaterized Debt") ///
	vlines(010000010001000001{0}) multicol(1,2,10;1,12,10)
	matrix portfolio_changes = portfolio_changes_3_`j'[1...,2..11] , portfolio_changes_4_`j'[1...,2..11] 
	frmttable using "${tabdir}table`ps'_e", statmat(portfolio_changes) tex $basefont $titlfont replace $coljust title("(b): Top 10\%") $format $rtitles ///
	ctitles("","\textbf{90\% - 99\%}","","","","","","","","","","\textbf{Top 1\%}","","","","","","","","",""\"","Housing","Home Equity","Business","Ret. Accts.","Fin. Assets$^a$","Other Assets","Housing Debt", ///
	"Nonhousing Debt","Collaterized Debt","Uncollaterized Debt","Housing","Home Equity","Business","Ret. Accts.","Fin. Assets$^a$","Other Assets","Housing Debt","Nonhousing Debt","Collaterized Debt","Uncollaterized Debt") ///
	vlines(010000010001000001{0}) multicol(1,2,10;1,12,10) addtable
	local ++ps 
}

* Export to Excel 
local ps = $ps
forvalues j = 1/3{
	putexcel set "${resdir}table`ps'", sheet("Bottom 50%", replace) replace 
    putexcel A1 = matrix(portfolio_changes_1_`j'), colnames
	putexcel set "${resdir}table`ps'", sheet("50%-90%", replace) modify 
    putexcel A1 = matrix(portfolio_changes_2_`j'), colnames 
    putexcel set "${resdir}table`ps'", sheet("90%-99%", replace) modify 
    putexcel A1 = matrix(portfolio_changes_3_`j'), colnames 
	putexcel set "${resdir}table`ps'", sheet("Top 1%", replace) modify 
    putexcel A1 = matrix(portfolio_changes_4_`j'), colnames 
	local ++ps
}


**# Overlap between top of distributions

**## Compute shares 

* Generate identifyer for each top group
use "${qrdata}qr5data${maxyear}.dta", clear
foreach var of varlist networth income earnings{
	if "`var'" == "networth"{
		local svarlist earnings income
	}
	else if "`var'" == "earnings"{
		local svarlist income networth
	}
	else{
		local svarlist earnings networth
	}
	sort `var' id `svarlist', stable
	tempvar sumwgt 
	gen `sumwgt' = sum(wgt1)
	qui sum `sumwgt'
	gen top1_`var' = (`sumwgt' > .99 * r(max))
}

* Calculate shares of those also in other top groups
matrix overlap = J(3,3,.)
matrix colnames overlap = "Wealth" "Income" "Earnings"
matrix rownames overlap = "Wealth" "Income" "Earnings"
local i = 1
foreach var of varlist networth income earnings{
	if "`var'" == "networth"{
		local vvarlist income earnings
		local j = 2
		local jc "++j"
	}
	else if "`var'" == "earnings"{
		local vvarlist networth income
		local j = 1
		local jc "++j"
	}
	else{
		local vvarlist networth earnings
		local j = 1
		local jc "j = 3"
	}
	matrix overlap[`i',`i'] = 100
	qui sum `var' [aw=wgt1] if top1_networth == 1 // calculate sum_w always from top1_networth (top1_income is not exactly 1%)
	local twgt = r(sum_w)
	foreach vvar of varlist `vvarlist'{
		qui sum `var' [aw=wgt1] if top1_`var' == 1 & top1_`vvar' == 1
		matrix overlap[`i',`j'] = round(100*(r(sum_w)/`twgt'),0.1)
		local `jc'
	}
	local ++i
}

**## Write table

* Store lower triangle in matrix to be used for frmttable
matrix toverlap = J(3,3,.) 
matrix colnames toverlap = "Wealth" "Income" "Earnings"
matrix rownames toverlap = "Wealth" "Income" "Earnings" 
forvalues r = 1/3{
	forvalues c = 1/3{
		if `r' >= `c'{ 
		    matrix toverlap[`r',`c'] = overlap[`r',`c'] 
		}
	}
}
frmttable using "${tabdir}table$ol", statmat(toverlap) tex $basefont $titlfont replace $coljust title("Overlap Between the Top 1\% of Wealth, Income, and Earnings Distributions")  $format

**## Export to Excel 
putexcel set "${resdir}table$ol", sheet("Top Groups Overlap", replace) replace 
putexcel A1 = matrix(overlap), names


**# Share of Households with Wealth and Income Multiples of the Median

**## Calculate shares  
matrix share_mm = J(${numyear},7,.)
matrix colnames share_mm = "year" "inc_10" "inc_25" "inc_50" "nw_10" "nw_25" "nw_50"
local i = 1
forvalues y = $minyear (3) $maxyear{
	matrix share_mm[`i',1] = `y'
	use "${qrdata}qr5data`y'.dta", clear
	qui sum income [aw=wgt1]
	local numhh = r(sum_w)
	local j = 2
	foreach var of varlist income networth{
		qui sum `var' [aw=wgt1], d
		local median = r(p50)
		foreach mm in 10 25 50{
			qui sum `var' [aw=wgt1] if `var' > `mm' * `median'
			matrix share_mm[`i',`j'] = round(100*(r(sum_w)/`numhh'),0.1)
			local ++j
		} 
	}
	local ++i
}

**## Write table 
matrix table = share_mm[1...,2...]
frmttable using "${tabdir}table${mm}", statmat(table) $rtitles ctitles("","Income","","","Wealth","",""\"","$>10\times$","$>25\times$","$>50\times$","$>10\times$","$>25\times$","$>50\times$") ///
tex $basefont $titlfont replace $coljust $format title("Share of Households with Wealth and Income Multiples of the Median") vlines(01001{0}) multicol(1,2,3;1,5,3)

**## Export to Excel 
putexcel set "${resdir}table$mm", sheet("HHs above Median Multiple", replace) replace 
putexcel A1 = matrix(share_mm), colnames
