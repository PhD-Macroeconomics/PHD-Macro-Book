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

capture log close
log using "${master1}dofiles/results/QR2022.log" , replace text

global dodir = "${master1}dofiles/"
global resdir = "${master1}results/"
global tabdir = "${master2}tables/"
global figdir = "${master2}figures/"
global qrdata = "${master2}data/"

* Gloabl for coding of employment status according to CPS (set to 1 for alternative coding)
global ALTcode = 0 

* Globals for figure formatting 
global fsa = "8-15" // Number of figures for saving attitudes
global fsat = "15" // Number of figure for time trend in saving attitudes
global sa1 = "25" // sa1-sa5 are the codes of the reasons for saving considered in the time trend graph (25 = Emergencies - top 1 reason among all HHs in 2022)
global l1 = "Emergencies" // global for legend of figure for time trends in saving attitudes
global sa2 = "22" // 22 = Retirement/old age - top 2 reason among all HHs in 2022
global l2 = "Retirement/old age"
global sa3 = "3" // 3 = For children/family - top 3 reason among all HHs in 2022
global l3 = "For children/family"
global sa4 = "15" // 15 = Taking time off - top 4 reason among all HHs in 2022
global l4 = "Taking time off"
global sa5 = "32" // 32 = For future - top 5 reason among all HHs in 2022
global l5 = "For future"

* Globals for table formatting
global basefont = "basefont(rm small)"  //  base font for all text (rm = Roman, small = smaller than default font size)
global titlfont = "titlfont(large)" // font for table title (large = bigger than default font size, normalsize = default font size)
global coljust = "coljust(l{c}c)" // specifies whether the table columns are left, center, or right justified (l{c}c = all columns are center justified, except the first, which is left justified)
global format = "sfmt(g) sdec(0)" // numerical format for statistics (option sfmt(g) together with sdec(0) sets format to %8.0g)
global tq = "1" // Number of table for Quantiles of the Earnings, Income, and Wealth Distributions
global tcs = "2" // Number of table for Concentration and Skewness of the Distributions
global tcc = "3" // Number of table for Correlation Coefficients of Earnings, Income, and Wealth
global tp = "4" // Number of table for Earnings Partition (Number of table for Income/Wealth Partition will be tp+1/tp+2)
global tpp = "$tp + 3" // Number of table for Age Partition (Number of table for Education/Employment/Marital Partition will be tp+4/tp+5/tp+6)
global ttt = "11" // Number of table for time trends 
global tfs = "12" // Number of table for family status 
global tls = "13" // Number of table for labor market status
global nc = "14" // Number of table for number of children by income/wealth group 
global nct = "15" // Number of table for time trends of number of children by income/wealth group 
global rin = "16" // Number of table for regression of income/wealth on industry
global roc = "17" // Number of table for regression of income/wealth on occat 

* Globals for regressions
global rci = 0 // reference category for regression of income/wealth on industry (select number from 0 to 7; 0=not doing any work for pay)
global rco = 0 // reference category for regression of income/wealth on occat (select number from 0 to 6; 0=not doing any work for pay)



/* Put here CPI of base year and base year. The CPI of the base year can be read 
   off the denominator of the "cpiadj" factor below. */

global basecpi = 4376
global baseyear = 2022


global minyear = 1989
global maxyear = 2022
local nyears = round(($maxyear - $minyear)/3) + 1
matrix timetrend1 = J(`nyears',5,.)
matrix colnames timetrend1 = "year" "earnings" "income" "wealth" "N-H-W" 
forvalues j = 1(1)8 {
	matrix timetrend2_s`j' = J(`nyears',5,.)
	matrix colnames timetrend2_s`j' = "year" "earnings" "income" "wealth" "N-H-W" 
	}	

matrix timetrend3 = J(`nyears',10,.)
matrix colnames timetrend3 = "year" "earnings30th" "income30th" "wealth30th" "earnings50th" "income50th" "wealth50th" "earnings90th" "income90th" "wealth90th"  
	
	
forvalues y = $minyear(3)$maxyear {
	display "================================" _newline "`y'" _newline "================================"
		if(`y' == 1989) {
			global cpilag = 1886/1808
			global cpiadj = ${basecpi}/1902 
			}
		else if(`y' == 1992) {
			global cpilag = 2103/2051
			global cpiadj = ${basecpi}/2116 
			}
		else if(`y' == 1995){
			global cpilag = 2254/2201
			global cpiadj = ${basecpi}/2265 
			}
		else if(`y' == 1998){
			global cpilag = 2397/2364
			global cpiadj = ${basecpi}/2405 
			}
		else if(`y' == 2001){
			global cpilag = 2600/2529
			global cpiadj = ${basecpi}/2618 
			}
		else if(`y' == 2004){
			global cpilag = 2774/2701
			global cpiadj = ${basecpi}/2788 
			}
		else if(`y' == 2007){
			global cpilag = 3045/2961
			global cpiadj = ${basecpi}/3062 
			}
		else if(`y' == 2010){
			global cpilag = 3202/3150
			global cpiadj = ${basecpi}/3208 
			}
		else if(`y' == 2013){
			global cpilag = 3421/3372
			global cpiadj = ${basecpi}/3438 
			}
		else if(`y' == 2016){
		    global cpilag = 3526/3482
    	    global cpiadj = ${basecpi}/3547
		    }
	    else if(`y' == 2019){
		    global cpilag = 3765/3698
    	    global cpiadj = ${basecpi}/3781
		}
	    else if(`y' == 2022){
		     global cpilag = 4315/3992
    	     global cpiadj = ${basecpi}/4376
		}
	

	/* Change definition of other income and transfers, and employment status */
	tempfile oincdata`y'
	local stubyear = mod(`y',100)
	if(`stubyear' < 10) {
		use "${master2}`y'/scf200`stubyear'.dta", clear
		}
	else if(`stubyear' >= 10 & `stubyear' <= 22) {
		use "${master2}`y'/scf20`stubyear'.dta", clear
		}
	else {
		use "${master2}`y'/scf`stubyear'.dta", clear
		}
	/* Rename HH id for 1989 */
	if(`y' == 1989) {	
		rename X1 Y1
		}
	/* Recode capital letters after 2007 */
	if(`y' >= 2004 | `y' == 1989 ) {
		rename Y1 y1
		foreach xvar of numlist 5718 5720 5722 5724 5910 4100 101 8023 7401 3006 3007{
			rename X`xvar' x`xvar'
			}
		}
	if(`y' >= 2004){
	     foreach xvar of numlist 6670 6671 6672 6673 6674 6675 6676 6677 7513 7514 7515 6848{
			rename X`xvar' x`xvar'
			}
	}
	
    if(`y' == 1989){
		keep y1 x5718 x5720 x5722 x5724 x5910 x4100 x101 x8023 x7401 x3006 x3007
	}
	else if `y' == 1992{
	    keep y1 x5718 x5720 x5722 x5724 x5910 x4100 x101 x8023 x7401 x3006 x3007 x7513 x7514 x7515
	}
    else if `y' == 1995{
	    keep y1 x5718 x5720 x5722 x5724 x5910 x4100 x101 x8023 x7401 x6670 x6671 x6672 x6673 x6674 x6675 x6676 x6677 x3006 x3007 x7513 x7514 x7515
	}
	else{
	    keep y1 x5718 x5720 x5722 x5724 x5910 x4100 x101 x8023 x7401 x6670 x6671 x6672 x6673 x6674 x6675 x6676 x6677 x3006 x3007 x7513 x7514 x7515 x6848
	}
	
	rename y1 id
	
	/* CPI adjustment for income */
	foreach kvar in "x5718" "x5720" "x5722" "x5724" {
		quietly : replace `kvar' = `kvar' * $cpilag * $cpiadj
		}
		
	save `oincdata`y'', replace
	use "${master2}scfwealth_cpi${baseyear}.dta", clear

	/* Replicate Diaz-Gimenez, Glover, Rios-Rull, QR 2011 (DGR)*/
	keep if year == `y'
	
	/* Merge other income and transfer data */
	quietly : merge 1:1 id using `oincdata`y''
	capture drop pensionwithdrawal
	gen pensionwithdrawal = otherincome - (x5718 + x5720 + x5724) 
	replace otherincome = x5718 + x5724
	replace socialsecurity = x5720 + x5722 + pensionwithdrawal
	drop _merge x5718 x5720 x5722 x5724 pensionwithdrawal
	
	/* Only retired in occat 3 */
	replace occat = 4 if occat == 3 & x4100 ~= 50
	gen disabled = (x4100 == 52)
	//replace occat = 5 if occat == 4 & disabled == 1
	label define occat 1 "worker" 2 "self-employed" 3 "retired" 4 "non-workers" 
	label variable occat occat
	
	/* Official title of job 
	   0: not doing any work for pay
	   1: Management Occupations; Business Operations Specialists; Financial Sepcialists; Computer and Mathematical Occupations;
	      Architecture and Engineering Occupations; Life, Physical, and Social Science Occupations; Community and Social Services 
		  Occupations; Legal Occupations; Education, Training, and Library Occupations;  Arts, Design, Entertainment, Sports, and 
		  Media Occupations; Healthcare Practitioners and Technical Occupations; Healthcare Support Occupations
	   2: Architecture and Engineering Occupations; Sales and Related Occupations; Office and Administrative Support Occupations
	   3: Protective Service Occupations; Food Preparation and Serving Related Occupations; Building and Grounds Cleaning and 
	      Maintenance Occupations; Personal Care and Service Occupations; Armed Forces 
	   4: Construction Trades; Extraction Workers; Installation, Maintenance, and Repair Workers; Production Occupations; 
	   5: Other Production Occupations; Transportation and Material Moving Occupations
	   6: Farming, Fishing, and Forestry Occupations
	*/
	gen jobtitle = x7401 

	/* Labor Market Status according to CPS */
	gen laborforcestatus = x4100
	label define laborforcestatus 1 "employed" 2 "unemployed" 3 "out of the labor force" 
	if(${ALTcode} == 1){ 	
	    /* Alternative coding */
	    recode laborforcestatus (11 = 1) (12/15 = 3) (22 = 1) (90 96 = 1) (16/17 = 2) (20 = 2) (30 = 2) (21 = 3) (23/24 = 3) (50/85  = 3) (97 = 3)
	}
	else {
		recode laborforcestatus (11/15 = 1) (16/17 = 2) (20 = 2) (21 = 3) (22 = 3) (23 = 3) (24 = 3) (30 = 2) (50/85 = 3) (90 = 1) (96 = 1) (97 = 3)

	}
	label values laborforcestatus laborforcestatus
	if(`y' >= 1995) {
		replace laborforcestatus = 3
		foreach lfvar in x6670 /*x6671 x6672 x6673 x6674 x6675 x6676 x6677*/ {
			replace laborforcestatus = 1 if `lfvar' == 1
			replace laborforcestatus = 2 if `lfvar' == 3 & laborforcestatus ~= 1
		}		
	}
	if(`y' < 1995){
	    drop x4100
	}
	else{
		drop x4100 x6670 x6671 x6672 x6673 x6674 x6675 x6676 x6677
	}
	
	/* Marital status */
	gen maritalstatus = x8023
	recode maritalstatus (1/2 = 1) (3/4 = 2) (5 = 3) (6 0 = 4)
	label define maritalstatus 1 "married" 2 "divorced" 3 "widowed" 4 "never married"
	label variable maritalstatus maritalstatus
	drop x8023
	
	/* Number of children including children outside the household */
	gen children = (kids > 0 | x5910 > 0)
	label define children 0 "no children" 1 ">= 1 children"
	label variable children children
	gen nchildren = x5910 
	qui replace nchildren = 0 if nchildren < 0 // x5910 = -1 if no children outside of household 
	qui replace nchildren = nchildren + kids 
	label var nchildren "Number of children including children outside the household"
	drop x5910
	
	/* Recode education */
	if `y' <= 2013{
	    drop educl_spouse
		do "${dodir}recodeeducation.do"
	}
	else{
	    rename educl educl_head
	    label values educl_head educl_spouse educllabel
	}
	
	
	/* Variable list */
	local varlist = "earnings income networth"
	local varlista = "earnings income networth" // networth_nohousing"
	local varlist1 = "earnings income networth" // networth_nohousing houses mrthel"
	local varlisttime = "earnings income networth networth_nohousing"
	local inclist = "labor capital business transfer other"
	local splist = "housecars businessnonfin financialassets colldebt nocolldebt"
	local sslist = "0100 01 15 510 q1 q2 q3 q4 q5 9095 9599 99100" 
	matrix qsize = (1\4\5\20\20\20\20\20\5\4\1\100)
	matrix qpoint = ( 0,0.01\0.01,0.05\0.05,0.10\0,0.20\0.20,0.40\0.40,0.60\0.60,0.80\0.80,1\0.90,0.95\0.95,0.99\0.99,1\0,1)

	/* Determine labor income share as ratio of labor income to 
	   sum of labor income interest and dividend income, and capital gains */
	/* Version 1 */
	gen laborincomeshare = laborincome /(laborincome + intdivincome + capitalgains)
	quietly: sum laborincomeshare [aw = wgt1], d
	local laborincshare = r(mean)
	drop laborincomeshare
	/* Version 2 */
	quietly: sum laborincome [aw = wgt1], d
	local meanlaborincome = r(mean)
	gen capitalincome = intdivincome +  capitalgains
	quietly: sum capitalincome [aw = wgt1], d
	local meancapitalincome = r(mean)
	local laborincshare2 = `meanlaborincome'/(`meancapitalincome' + `meanlaborincome')

	/* DGR use version 2 */
	display "Labor income shares " round(100 * `laborincshare',0.1) " (Version 1) " round(100 * `laborincshare2',0.1) " (Version 2)." 

	/* Generate earnings as labor income plus laborincome share times business income */
	gen earnings = laborincome + `laborincshare2' * busifarmincome
	gen transfers = socialsecurity + unemployment 
	/* Income shares */
	gen businessincome = busifarmincome
	gen transferincome = transfers 
	
	/* Replace income by sum of income components total income */
	replace income = laborincome + capitalincome + businessincome + transferincome + otherincome

	/* Networth no housing */
	gen networth_nohousing = networth - homeequity
	
	/* Generate asset categories for balance sheet decomposition */
	gen housecars = houses + vehicles 
	gen businessnonfin = othresrealest + nonresrealest + business + othernonfinassets
	gen colldebt = - (mrthel + residentialdebt + installment) 
	gen nocolldebt = - (othloc + creditcard + otherdebt)
	
	/* Generate new age classes */
	drop agecl
	gen agecl = 1 + (age >= 31) + (age >= 46) + (age > 65)
	gen ageclfine = 1 + (age >= 26) + (age >= 31) + (age >= 36) + (age >= 41) + (age >= 46) + (age >= 51) + (age >= 56) + (age >= 61) + (age > 65)
	
	/* Generate marital status */
	gen marital = (married == 1) + (married == 2 & x101 > 1) * 2 + (married == 2 & x101 == 1) * 3
	gen familysize = x101 
	gen retiredwidow = (occat == 3 & maritalstatus == 3)
	
	
	/* Family status for table 14
	   1 : married
	   2 : single
	   3 : single w/ dependents
	   4 : male single w/ dependents
	   5 : female single w/ dependents
	   6 : single w/o dependents
	   7 : male single w/o dependents
	   8 : female single w/o dependents
	   9 : retired female widows w/o dependents
	*/
	quietly {
		forvalues i = 1(1)9 {
			gen familystatus`i' = 0
			if ( `i' == 1) {
				replace familystatus`i' = 1 if married == 1
				}
			else if( `i' == 2) {
				replace familystatus`i' = 1 if married == 2
				}
			else if( `i' == 3) {
				replace familystatus`i' = 1 if married == 2 & x101 > 1
				}
			else if( `i' == 4) {
				replace familystatus`i' = 1 if married == 2 & x101 > 1 & sex == 1
				}
			else if( `i' == 5) {
				replace familystatus`i' = 1 if married == 2 & x101 > 1 & sex == 2
				}
			else if( `i' == 6) {
				replace familystatus`i' = 1 if married == 2 & x101 == 1
				}
			else if( `i' == 7) {
				replace familystatus`i' = 1 if married == 2 & x101 == 1 & sex == 1
				}
			else if( `i' == 8) {
				replace familystatus`i' = 1 if married == 2 & x101 == 1 & sex == 2
				}
			else if( `i' == 9) {
				replace familystatus`i' = 1 if retiredwidow == 1 & x101 == 1 & sex == 2
				}
			}
		}
	drop x101
	
	/* Save file for analysis in auxiliary programs */
	save "${qrdata}qr5data`y'.dta", replace
	
	/* Income density plot */
	gen fwt = round(wgt1 * 100000000)
	foreach hvar in `varlist' {
	    if "`hvar'" == "earnings"{
		    local xtitle "Household earnings"
		}
		else if "`hvar'" == "income"{
		    local xtitle "Household income"
		}
		else{
		    local xtitle "Household wealth"
		}
		quietly : sum `hvar' [aw = wgt1]
		local minc = r(mean)
		histogram `hvar' if `hvar' >= - 0.5 * abs(`minc') & `hvar' <= 5 * abs(`minc') [fw = fwt], bin(250) percent kdensity kdenopts(kernel(gaussian) bwidth(5000)) xtitle("`xtitle'")
		local figname = "`hvar'"
		graph export "${figdir}`figname'distribution`y'.eps", as(eps) replace
		}

	/******************************************************************************/
	/* Time trends */
	local cy = round((`y' - $minyear)/3) + 1
	matrix timetrend1[`cy',1] = `y'
	matrix timetrend2_s1[`cy',1] = `y'
	matrix timetrend2_s2[`cy',1] = `y'
	matrix timetrend2_s3[`cy',1] = `y'
	matrix timetrend2_s4[`cy',1] = `y'
	matrix timetrend2_s5[`cy',1] = `y'
	matrix timetrend2_s6[`cy',1] = `y'
	matrix timetrend2_s7[`cy',1] = `y'
	matrix timetrend2_s8[`cy',1] = `y'
	matrix timetrend3[`cy',1] = `y'
	local i = 2
	foreach vvar in `varlisttime' {
		quietly : sum `vvar' [aw = wgt1], d
		local cs = r(mean)
		local xmean = r(mean)
		local xmedian = r(p50)
		matrix timetrend1[`cy',`i'] = `cs'
	
		quietly : sum `vvar' [aw = wgt1], d
		local cv = r(sd)/r(mean)
		local xmean = r(mean)
		local xmedian = r(p50)
		local mean2median = `xmean'/`xmedian'
		local allwgt = r(sum_w)
		local xmin = r(min)
		local xmax = r(max)
		quietly : _pctile `vvar' [aw = wgt1], p(30 40 90 99)
		local q40 = r(r2)
		local q99 = r(r4)
		local q30 = r(r1)
		local q90 = r(r3)
		quietly : sum `vvar' [aw = wgt1] , d
		local q50 = r(p50)
		local q99 = r(p99)
		local ratio9950 = `q99'/`q50'
		quietly : sgini `vvar' [aw = wgt1]
		local ginicoeff = r(coeff)
		
		quietly: sum `vvar' if `vvar' <= `xmean' [aw = wgt1], d
		local lowwgt = r(sum_w)
		
		gen templog = log(`vvar')
		quietly : sum templog [aw = wgt1], d
		local logvar = r(Var)
		drop templog
		
		local ratio9050 = `q90'/`xmedian'
		local ratio5030 = `xmedian'/`q30'
		
		matrix timetrend2_s1[`cy',`i'] = round(`cv',0.01)
		matrix timetrend2_s2[`cy',`i'] = round(`logvar',0.01)
		matrix timetrend2_s3[`cy',`i'] = round(`ginicoeff',0.01)
		matrix timetrend2_s4[`cy',`i'] = round(`ratio9950',0.01)
		matrix timetrend2_s5[`cy',`i'] = round(100 * `lowwgt'/`allwgt')
		matrix timetrend2_s6[`cy',`i'] = round(`mean2median',0.01)
		matrix timetrend2_s7[`cy',`i'] = round(`ratio9050',0.01)
		matrix timetrend2_s8[`cy',`i'] = round(`ratio5030',0.01)
		
		if(`i' <= 4 ) {
			local i30 = `i'
			local i50 = `i' + 3
			local i90 = `i' + 6
			matrix timetrend3[`cy',`i30'] = `q30'
			matrix timetrend3[`cy',`i50'] = `xmedian'
			matrix timetrend3[`cy',`i90'] = `q90'
			}
		local i = `i' + 1
		}
	
	/******************************************************************************/
	
	quietly{
		matrix table1 = J(3,13,.)
		matrix rownames table1 = "earnings" "income" "wealth" //"N-H-W" 
		matrix colnames table1 = "0" "1" "5" "10" "20" "40" "50" "60" "80" "90" "95" "99" "100"

		matrix table2 = J(8,3,.)
		matrix colnames table2 = "earnings" "income" "wealth" //"N-H-W" 
		matrix rownames table2 = "CoefVar" "Varlogs" "Gini" "99-50-ratio" "LocMean" "mean-to-median" "90-50-ratio" "50-30-ratio"

		matrix table1x = J(3,12,.)
		matrix rownames table1x = "earnings" "income" "wealth" //"N-H-W" 
		matrix colnames table1x = "0" "1" "5" "10" "20" "40" "60" "80" "90" "95" "99" "100"
		
		/* Averages by age groups */
		matrix table111 = J(11,3,.)
		matrix colnames table111 = "earnings" "income" "wealth" 
		matrix rownames table111 = "-25" "26-30" "31-35" "36-40" "41-45" "46-50" "51-55" "56-60" "61-65" "66+" "total"
		
		/* Income sources by age groups */
		matrix table112 = J(11,5,.)
		matrix colnames table112 = "labor" "capital" "business" "transfer" "other"
		matrix rownames table112 = "-25" "26-30" "31-35" "36-40" "41-45" "46-50" "51-55" "56-60" "61-65" "66+" "total"
		
		/* Gini by age groups */
		matrix table113 = J(11,3,.)
		matrix colnames table113 = "earnings" "income" "wealth"
		matrix rownames table113 = "-25" "26-30" "31-35" "36-40" "41-45" "46-50" "51-55" "56-60" "61-65" "66+" "total"
		
		/* Coefficient of variation by age groups */
		matrix table114 = J(11,3,.)
		matrix colnames table114 = "earnings" "income" "wealth"
		matrix rownames table114 = "-25" "26-30" "31-35" "36-40" "41-45" "46-50" "51-55" "56-60" "61-65" "66+" "total"
		
		/* Share and size of households */
		matrix table115 = J(11,2,.)
		matrix colnames table115 = "share" "size"
		matrix rownames table115 = "-25" "26-30" "31-35" "36-40" "41-45" "46-50" "51-55" "56-60" "61-65" "66+" "total"
		
		/* Averages by education */
		//matrix table121 = J(5,3,.)
		matrix table121 = J(5,3,.)
		matrix colnames table121 = "earnings" "income" "wealth" 
		/* Coarse partition */
		//matrix rownames table121 =  "Dropouts" "High-school" "Some-college" "College" "total"
		/* Fine partition */
		matrix rownames table121 =  "Dropouts" "High-school" "Some-college" "College" "total"
		
		
		/* Income sources by education */
		//matrix table122 = J(5,5,.)
		matrix table122 = J(5,5,.)
		matrix colnames table122 = "labor" "capital" "business" "transfer" "other"
		/* Coarse partition */
		//matrix rownames table122 =  "Dropouts" "High-school" "Some-college" "College" "total"
		/* Fine partition */
		matrix rownames table122 =  "Dropouts" "High-school" "Some-college" "College" "total"
		
		/* Gini by education groups */
		//matrix table123 = J(5,3,.)
		matrix table123 = J(5,3,.)
		matrix colnames table123 = "earnings" "income" "wealth"
		/* Coarse partition */
		//matrix rownames table123 =  "Dropouts" "High-school" "Some-college" "College" "total"
		/* Fine partition */
		matrix rownames table123 =  "Dropouts" "High-school" "Some-college" "College" "total"
		
		/* Coefficient of variation by education */
		//matrix table124 = J(5,3,.)
		matrix table124 = J(5,3,.)
		matrix colnames table124 = "earnings" "income" "wealth"
		/* Coarse partition */
		//matrix rownames table124 =  "Dropouts" "High-school" "Some-college" "College" "total"
		/* Fine partition */
		matrix rownames table124 =  "Dropouts" "High-school" "Some-college" "College" "total"
		
		/* Share and size of households */
		//matrix table125 = J(5,2,.)
		matrix table125 = J(5,2,.)
		matrix colnames table125 = "share" "size"
		/* Coarse partition */
		//matrix rownames table125 =  "Dropouts" "High-school" "Some-college" "College" "total"
		/* Fine partition */
		matrix rownames table125 =  "Dropouts" "High-school" "Some-college" "College" "total"
		
		/* Averages by employment */
		matrix table131 = J(6,3,.)
		matrix colnames table131 = "earnings" "income" "wealth" 
		matrix rownames table131 =  "Workers" "Self-employed" "Retired" "Nonworkers" "Disabled" "total"
		
		/* Income sources by employment */
		matrix table132 = J(6,5,.)
		matrix colnames table132 = "labor" "capital" "business" "transfer" "other"
		matrix rownames table132 =  "Workers" "Self-employed" "Retired" "Nonworkers" "Disabled" "total"
		
		/* Gini by employment groups */
		matrix table133 = J(6,3,.)
		matrix colnames table133 = "earnings" "income" "wealth"
		matrix rownames table133 = "Workers" "Self-employed" "Retired" "Nonworkers" "Disabled" "total"
		
		/* Coefficient of variation by employment */
		matrix table134 = J(6,3,.)
		matrix colnames table134 = "earnings" "income" "wealth"
		matrix rownames table134 = "Workers" "Self-employed" "Retired" "Nonworkers" "Disabled" "total"
		
		/* Share and size of households */
		matrix table135 = J(6,2,.)
		matrix colnames table135 = "share" "size"
		matrix rownames table135 = "Workers" "Self-employed" "Retired" "Nonworkers" "Disabled" "total"
		
	
		/* Averages by family status */
		matrix table141 = J(10,3,.)
		matrix colnames table141 = "earnings" "income" "wealth" 
		matrix rownames table141 =  "married" "single" "single-w-dependents" "male-single-w-dependents" "female-single-w-dependents" /*
		*/ "single-w-o-dependents" "male-single-w-o-dependents" "female-single-w-o-dependents" "retired-female-widows" "total"
		
		/* Income sources by family status */
		matrix table142 = J(10,5,.)
		matrix colnames table142 = "labor" "capital" "business" "transfer" "other"
		matrix rownames table142 = "married" "single" "single-w-dependents" "male-single-w-dependents" "female-single-w-dependents" /*
		*/ "single-w-o-dependents" "male-single-w-o-dependents" "female-single-w-o-dependents" "retired-female-widows" "total"
		
		/* Gini by age groups */
		matrix table143 = J(10,3,.)
		matrix colnames table143 = "earnings" "income" "wealth"
		matrix rownames table143 = "married" "single" "single-w-dependents" "male-single-w-dependents" "female-single-w-dependents" /*
		*/ "single-w-o-dependents" "male-single-w-o-dependents" "female-single-w-o-dependents" "retired-female-widows" "total"
		
		/* Coefficient of variation by family status */
		matrix table144 = J(10,3,.)
		matrix colnames table144 = "earnings" "income" "wealth"
		matrix rownames table144 = "married" "single" "single-w-dependents" "male-single-w-dependents" "female-single-w-dependents" /*
		*/ "single-w-o-dependents" "male-single-w-o-dependents" "female-single-w-o-dependents" "retired-female-widows" "total"
		
		/* Share and size of households */
		matrix table145 = J(10,2,.)
		matrix colnames table145 = "share" "size"
		matrix rownames table145 = "married" "single" "single-w-dependents" "male-single-w-dependents" "female-single-w-dependents" /*
		*/ "single-w-o-dependents" "male-single-w-o-dependents" "female-single-w-o-dependents" "retired-female-widows" "total"
		
		local i = 1
		foreach vvar in `varlista' {
			quietly : sum `vvar' [aw = wgt1], d
			local cv = r(sd)/r(mean)
			local xmean = r(mean)
			local xmedian = r(p50)
			local mean2median = `xmean'/`xmedian'
			local allwgt = r(sum_w)
			local xmin = r(min)
			local xmax = r(max)
			quietly : _pctile `vvar' [aw = wgt1], p(30 40 90 99)
			local q40 = r(r2)
			local q99 = r(r4)
			local q30 = r(r1)
			local q90 = r(r3)
			quietly : sum `vvar' [aw = wgt1], d 
			local q50 = r(p50)
			local q99 = r(p99)
			local ratio9950 = `q99'/`q50'
			quietly : sgini `vvar' [aw = wgt1]
			local ginicoeff = r(coeff)
			
			quietly: sum `vvar' if `vvar' <= `xmean' [aw = wgt1], d
			local lowwgt = r(sum_w)
			
			gen templog = log(`vvar')
			quietly : sum templog [aw = wgt1], d
			local logvar = r(Var)
			drop templog
			
			local ratio9050 = `q90'/`xmedian'
			local ratio5030 = `xmedian'/`q30'
			
			matrix table2[1,`i'] = round(`cv',0.01)
			matrix table2[2,`i'] = round(`logvar',0.01)
			matrix table2[3,`i'] = round(`ginicoeff',0.01)
			matrix table2[4,`i'] = round(`ratio9950',0.01)
			matrix table2[5,`i'] = round(100 * `lowwgt'/`allwgt')
			matrix table2[6,`i'] = round(`mean2median',0.01)
			matrix table2[7,`i'] = round(`ratio9050',0.01)
			matrix table2[8,`i'] = round(`ratio5030',0.01)
			
			quietly : _pctile `vvar' [aw = wgt1], p( 1 5 10 20 40 50 60 80 90 95 99 )
			matrix table1[`i',1] = round(1/1000 * `xmin',0.1)
			matrix table1[`i',2] = round(1/1000 * r(r1),0.1)
			matrix table1[`i',3] = round(1/1000 * r(r2),0.1)
			matrix table1[`i',4] = round(1/1000 * r(r3),0.1)
			matrix table1[`i',5] = round(1/1000 * r(r4),0.1)
			matrix table1[`i',6] = round(1/1000 * r(r5),0.1)
			matrix table1[`i',7] = round(1/1000 * r(r6),0.1)
			matrix table1[`i',8] = round(1/1000 * r(r7),0.1)
			matrix table1[`i',9] = round(1/1000 * r(r8),0.1)
			matrix table1[`i',10] = round(1/1000 * r(r9),0.1)
			matrix table1[`i',11] = round(1/1000 * r(r10),0.1)
			matrix table1[`i',12] = round(1/1000 * r(r11),0.1)
			matrix table1[`i',13] = round(1/1000 * `xmax',0.1)
			
			matrix table1x[`i',1] = `xmin'
			matrix table1x[`i',2] = r(r1)
			matrix table1x[`i',3] = r(r2)
			matrix table1x[`i',4] = r(r3)
			matrix table1x[`i',5] = r(r4)
			matrix table1x[`i',6] = r(r5)
			matrix table1x[`i',7] = r(r6)
			matrix table1x[`i',8] = r(r7)
			matrix table1x[`i',9] = r(r8)
			matrix table1x[`i',10] = r(r9)
			matrix table1x[`i',11] = r(r10)
			matrix table1x[`i',12] = `xmax'
			
			local i = `i' + 1
			}
	} // end quietly
		/***********************************************************************
		   AGE PARTITION 
		***********************************************************************/
		quietly {
			/* Age partition (by (fine) age groups) */
			/* (1) Mean, CV, and Gini */
			local i = 1
			foreach vvar in `varlista' {
				forvalues j = 1(1)10 {
					quietly : sum `vvar' if ageclfine == `j' [aw = wgt1], d
					local mv`j'`i' = r(mean)
					local cv = r(sd)/`mv`j'`i'' 
					matrix table111[`j',`i'] = round(`mv`j'`i''/1000,0.1)
					matrix table114[`j',`i'] = round(`cv',0.01)
					quietly : sgini `vvar' if ageclfine == `j' [aw = wgt1]
					local ginicoeff = r(coeff)
					matrix table113[`j',`i'] = round(`ginicoeff',0.01)
					} // end of j loop
				/* All households */
				local j = 11
				quietly : sum `vvar'  [aw = wgt1], d
				local mv`j'`i' = r(mean)
				local cv = r(sd)/`mv`j'`i'' 
				matrix table111[`j',`i'] = round(`mv`j'`i''/1000,0.1)
				matrix table114[`j',`i'] = round(`cv',0.01)
				quietly : sgini `vvar' [aw = wgt1]
				local ginicoeff = r(coeff)
				matrix table113[`j',`i'] = round(`ginicoeff',0.01)
				local i = `i' + 1
				} // end of i loop
			/* (2) Income sources */
			local i = 1
			foreach ivar in `inclist' {
				forvalues j = 1(1)10 {
					sum `ivar'income if ageclfine == `j' [aw = wgt1] 
					local ti = `mv`j'2'
					local is = r(mean)/abs(`ti')
					matrix table112[`j',`i'] = round(100 * `is',0.1)
					}
				local j = 11
				sum `ivar'income [aw = wgt1] 
				local ti = `mv`j'2'
				local is = r(mean)/abs(`ti')
				matrix table112[`j',`i'] = round(100 * `is',0.1)
				local i = `i' + 1
				} // end of ivar loop
			
			/* (3) Family size and share */
			local j = 11
			sum familysize  [aw = wgt1] , d
			local fz = r(mean)
			matrix table115[`j',2] = round(`fz',0.01)
			local twgt = r(sum_w)  
			matrix table115[`j',1] = 100
			
			forvalues j = 1(1)10 {
				sum familysize if ageclfine == `j' [aw = wgt1] , d
				local fz = r(mean)
				local sz = r(sum_w)
				matrix table115[`j',2] = round(`fz',0.01)
				matrix table115[`j',1] = round(100 *  `sz' / `twgt',0.1)
				}

			} // end quietly 

		/***********************************************************************
		   EDUCATION and EMPLOYMENT STATUS PARTITION 
		***********************************************************************/
		quietly {
			local ci = 2
			/* Coarse partition */
			//foreach cvar in "educl" "occat" {
			/* Coarse partition */
			foreach cvar in "educl_head" "occat" {
				/* Number of categories */
				local ncat = rowsof(table1`ci'1) - 1
				
				/* Age partition (by (fine) age groups) */
				/* (1) Mean, CV, and Gini */
				local i = 1
				foreach vvar in `varlista' {
					forvalues j = 1(1)`ncat' {
						quietly : sum `vvar' if `cvar' == `j' [aw = wgt1], d
						local mv`j'`i' = r(mean)
						local cv = r(sd)/`mv`j'`i''
						matrix table1`ci'1[`j',`i'] = round(`mv`j'`i''/1000,0.1)
						matrix table1`ci'4[`j',`i'] = round(`cv',0.01)
						cap quietly : sgini `vvar' if `cvar' == `j' [aw = wgt1]
						local ginicoeff = r(coeff)
						matrix table1`ci'3[`j',`i'] = round(`ginicoeff',0.01)
						/* Disabled as subgroup of the non-workers */
						if (`j' == `ncat' - 1 & "`cvar'" == "occat") {
							local j1 = `j' + 1
							quietly : sum `vvar' if `cvar' == `j' & disabled == 1 [aw = wgt1], d
							local mv`j1'`i' = r(mean)
							local cv = r(sd)/`mv`j1'`i''
							matrix table1`ci'1[`j1',`i'] = round(`mv`j1'`i''/1000,0.1)
							matrix table1`ci'4[`j1',`i'] = round(`cv',0.01)
							quietly : sgini `vvar' if `cvar' == `j' & disabled == 1 [aw = wgt1]
							local ginicoeff = r(coeff)
							matrix table1`ci'3[`j1',`i'] = round(`ginicoeff',0.01)
							continue, break
							}
						} // end of j loop
					/* All households */
					local j = `ncat' + 1
					quietly : sum `vvar'  [aw = wgt1], d
					local mv`j'`i' = r(mean)
					local cv = r(sd)/`mv`j'`i''
					matrix table1`ci'1[`j',`i'] = round(`mv`j'`i''/1000,0.1)
					matrix table1`ci'4[`j',`i'] = round(`cv',0.01)
					quietly : sgini `vvar' [aw = wgt1]
					local ginicoeff = r(coeff)
					matrix table1`ci'3[`j',`i'] = round(`ginicoeff',0.01)
					local i = `i' + 1
					} // end of i loop
				/* (2) Income sources */
				local i = 1
				foreach ivar in `inclist' {
					forvalues j = 1(1)`ncat' {
						sum `ivar'income if `cvar' == `j' [aw = wgt1] 
						local ti = `mv`j'2'
						local is = r(mean)/abs(`ti')
						matrix table1`ci'2[`j',`i'] = round(100 * `is',0.1)
						if (`j' == `ncat' - 1 & "`cvar'" == "occat") {
							local j1 = `j' + 1
							sum `ivar'income if `cvar' == `j' & disabled == 1 [aw = wgt1] 
							local ti = `mv`j1'2'
							local is = r(mean)/abs(`ti')
							matrix table1`ci'2[`j1',`i'] = round(100 * `is',0.1)
							continue, break
							}
						}
					local j = `ncat' + 1
					sum `ivar'income [aw = wgt1] 
					local ti = `mv`j'2'
					local is = r(mean)/abs(`ti')
					matrix table1`ci'2[`j',`i'] = round(100 * `is',0.1)
					local i = `i' + 1
					} // end of ivar loop
				
				/* (3) Family size and share */
				local j = `ncat' + 1
				sum familysize [aw = wgt1] , d
				local fz = r(mean)
				matrix table1`ci'5[`j',2] = round(`fz',0.01)
				local twgt = r(sum_w)  
				matrix table1`ci'5[`j',1] = 100
				
				forvalues j = 1(1)`ncat' {
					sum familysize if `cvar' == `j' [aw = wgt1] , d
					local fz = r(mean)
					local sz = r(sum_w)
					matrix table1`ci'5[`j',2] = round(`fz',0.01)
					matrix table1`ci'5[`j',1] = round(100 *  `sz' / `twgt',0.1)
					if (`j' == `ncat' - 1 & "`cvar'" == "occat") {
						local j1 = `j' + 1
						sum familysize if `cvar' == `j' & disabled == 1 [aw = wgt1] , d
						local fz = r(mean)
						local sz = r(sum_w)
						matrix table1`ci'5[`j1',2] = round(`fz',0.01)
						matrix table1`ci'5[`j1',1] = round(100 *  `sz' / `twgt',0.1)
						continue, break
						}
					}
				local ci = `ci' + 1
				}  // end for each 
			} // end quietly


		/***********************************************************************
		   FAMILY TYPE PARTITION 
		***********************************************************************/
		quietly {
			/* Family partition (by family status) */
			/* (1) Mean, CV, and Gini */
			local i = 1
			foreach vvar in `varlista' {
				forvalues j = 1(1)9 {
					quietly : sum `vvar' if familystatus`j' == 1 [aw = wgt1], d
					local mv`j'`i' = r(mean)
					local cv = r(sd)/`mv`j'`i'' 
					matrix table141[`j',`i'] = round(`mv`j'`i''/1000,0.1)
					matrix table144[`j',`i'] = round(`cv',0.01)
					quietly : sgini `vvar' if familystatus`j' == 1 [aw = wgt1]
					local ginicoeff = r(coeff)
					matrix table143[`j',`i'] = round(`ginicoeff',0.01)
					} // end of j loop
				/* All households */
				local j = 10
				quietly : sum `vvar'  [aw = wgt1], d
				local mv`j'`i' = r(mean)
				local cv = r(sd)/`mv`j'`i'' 
				matrix table141[`j',`i'] = round(`mv`j'`i''/1000,0.1)
				matrix table144[`j',`i'] = round(`cv',0.01)
				quietly : sgini `vvar' [aw = wgt1]
				local ginicoeff = r(coeff)
				matrix table143[`j',`i'] = round(`ginicoeff',0.01)
				local i = `i' + 1
				} // end of i loop
			/* (2) Income sources */
			local i = 1
			foreach ivar in `inclist' {
				forvalues j = 1(1)9 {
					sum `ivar'income if familystatus`j' == 1 [aw = wgt1] 
					local ti = `mv`j'2'
					local is = r(mean)/abs(`ti')
					matrix table142[`j',`i'] = round(100 * `is',0.1)
					}
				local j = 10
				sum `ivar'income [aw = wgt1] 
				local ti = `mv`j'2'
				local is = r(mean)/abs(`ti')
				matrix table142[`j',`i'] = round(100 * `is',0.1)
				local i = `i' + 1
				} // end of ivar loop
			
			/* (3) Family size and share */
			local j = 10
			sum familysize  [aw = wgt1] , d
			local fz = r(mean)
			matrix table145[`j',2] = round(`fz',0.01)
			local twgt = r(sum_w)  
			matrix table145[`j',1] = 100
			
			forvalues j = 1(1)9 {
				sum familysize if familystatus`j' == 1 [aw = wgt1] , d
				local fz = r(mean)
				local sz = r(sum_w)
				matrix table145[`j',2] = round(`fz',0.01)
				matrix table145[`j',1] = round(100 *  `sz' / `twgt',0.1)
				}

			} // end quietly 
			
		/**********************************************************************/
		/* Loop over conditioning variables earnings, income, and networth */
		quietly{
		forvalues j = 1(1)3 { 
			local tc = 41 + (`j' - 1) * 10
			local tc1 = `tc' + 1
			local tc2 = `tc1' + 1
			local tc3 = `tc2' + 1
			local tc4 = `tc3' + 1
			local tc5 = `tc4' + 1
			local tc6 = `tc5' + 1
			local tc7 = `tc6' + 1
			local tc8 = `tc7' + 1
			local cvar  : word `j' of `varlist'
			noisily display "Conditioning variable : `cvar'"
			
			/* Conditional averages */
			matrix table`tc' = J(3,12,.)
			matrix table`tc'x = J(3,12,.)
			matrix rownames table`tc' = "earnings" "income" "wealth" //"N-H-W" "houses" "mortgages" 
			matrix colnames table`tc' = "0-1" "1-5" "5-10" "1st" "2nd" "3th" "4th" "5th" "90-95" "95-99" "99-100" "all" 
			
			/* Shares of total samples in % */
			matrix table`tc1' = J(3,12,.)
			matrix rownames table`tc1' = "earnings" "income" "wealth" //"N-H-W" "houses" "mortgages"
			matrix colnames table`tc1' = "0-1" "1-5" "5-10" "1st" "2nd" "3th" "4th" "5th" "90-95" "95-99" "99-100" "all" 

			/* Income shares in % */
			matrix table`tc2' = J(5,12,.)
			matrix rownames table`tc2' = "labor" "capital" "business" "transfer" "other"
			matrix colnames table`tc2' = "0-1" "1-5" "5-10" "1st" "2nd" "3th" "4th" "5th" "90-95" "95-99" "99-100" "all" 

			/* Age */
			matrix table`tc3' = J(5,12,.)
			matrix rownames table`tc3' = "Under-31" "31-45" "46-65" "over-65" "average"
			matrix colnames table`tc3' = "0-1" "1-5" "5-10" "1st" "2nd" "3th" "4th" "5th" "90-95" "95-99" "99-100" "all" 

			/* Education */
			/* Coarse partition */
			matrix table`tc4' = J(4,12,.)
			matrix rownames table`tc4' = "Dropouts" "High-school" "Some-college" "College" 
			/* Fine partition */
			//matrix table`tc4' = J(5,12,.)
			//matrix rownames table`tc4' = "Dropouts" "High-school" "Some-college" "College" "Post-Graduate"
			matrix colnames table`tc4' = "0-1" "1-5" "5-10" "1st" "2nd" "3th" "4th" "5th" "90-95" "95-99" "99-100" "all" 

			/* Employment status */
			matrix table`tc5' = J(5,12,.)
			matrix rownames table`tc5' = "Workers" "Self-employed" "Retired" "Nonworkers" "Disabled" 
			matrix colnames table`tc5' = "0-1" "1-5" "5-10" "1st" "2nd" "3th" "4th" "5th" "90-95" "95-99" "99-100" "all" 

			/* Marital status */
			matrix table`tc6' = J(4,12,.)
			matrix rownames table`tc6' = "Married" "Single-wdep" "Single-wo-dep" "Family-size" 
			matrix colnames table`tc6' = "0-1" "1-5" "5-10" "1st" "2nd" "3th" "4th" "5th" "90-95" "95-99" "99-100" "all" 

			/* Marital status excl. retired widows */
			matrix table`tc7' = J(2,12,.)
			matrix rownames table`tc7' = "Single-wdep" "Single-wo-dep" 
			matrix colnames table`tc7' = "0-1" "1-5" "5-10" "1st" "2nd" "3th" "4th" "5th" "90-95" "95-99" "99-100" "all" 


			/* Assets, debt, houses, and mortgage debt */
			matrix table`tc8' = J(10,12,.) 
			matrix rownames table`tc8' = "housing_cars" "business_nonfin" "financial" "colldebt" "otherdebt" /*
			*/ "housing_cars_share" "business_nonfin_share" "financial_share" "colldebt_share" "otherdebt_share"
			matrix colnames table`tc8' = "0-1" "1-5" "5-10" "1st" "2nd" "3th" "4th" "5th" "90-95" "95-99" "99-100" "all" 

			
			/* Generate subsample variables */
			/* METHOD 1 : quantiles based on observed value at boundaries : problem is values are not increasing across quantiles*/
			/*
			gen c`j'sub0100  = 1
			gen c`j'sub01    = (`cvar' >= table1x[`j',1] & `cvar' <= table1x[`j',2])
			gen c`j'sub15    = (`cvar' > table1x[`j',2] & `cvar' <= table1x[`j',3])
			gen c`j'sub510   = (`cvar' > table1x[`j',3] & `cvar' <= table1x[`j',4])
			gen c`j'subq1    = (`cvar' <= table1x[`j',5])
			gen c`j'subq2    = (`cvar' > table1x[`j',5] & `cvar' <= table1x[`j',6])
			gen c`j'subq3    = (`cvar' > table1x[`j',6] & `cvar' <= table1x[`j',7])
			gen c`j'subq4    = (`cvar' > table1x[`j',7] & `cvar' <= table1x[`j',8])
			gen c`j'subq5    = (`cvar' > table1x[`j',8] )
			gen c`j'sub9095  = (`cvar' > table1x[`j',9] & `cvar' <= table1x[`j',10])
			gen c`j'sub9599  = (`cvar' > table1x[`j',10] & `cvar' <= table1x[`j',11])
			gen c`j'sub99100 = (`cvar' > table1x[`j',11] )
			*/
			/* METHOD 2 : Quantiles based on sum of weights (always strictly monotonically increasing) */
			/* Use lexiographic ordering to sort identical values in current variable */
			/* Rios-Rull et al. sort by id as second variable */
			if(`j' == 1) {
				sort `cvar' /*id*/ income networth, stable
				}
			if(`j' == 2){
				sort `cvar' /*id*/ earnings networth, stable
				}
			if(`j' == 3){
				sort `cvar' /*id*/ earnings income, stable
				}
			
			gen sumwgt = sum(wgt1)
			egen totalsumofwgt = max(sumwgt)
			gen c`j'sub0100  = 1
			gen c`j'sub01    = (sumwgt >= qpoint[1,1] * totalsumofwgt & sumwgt <= qpoint[1,2] * totalsumofwgt)
			gen c`j'sub15    = (sumwgt > qpoint[2,1] * totalsumofwgt  & sumwgt <= qpoint[2,2] * totalsumofwgt)
			gen c`j'sub510   = (sumwgt > qpoint[3,1] * totalsumofwgt  & sumwgt <= qpoint[3,2] * totalsumofwgt)
			gen c`j'subq1    = (sumwgt >= qpoint[4,1] * totalsumofwgt & sumwgt <= qpoint[4,2] * totalsumofwgt)
			gen c`j'subq2    = (sumwgt > qpoint[5,1] * totalsumofwgt  & sumwgt <= qpoint[5,2] * totalsumofwgt)
			gen c`j'subq3    = (sumwgt > qpoint[6,1] * totalsumofwgt  & sumwgt <= qpoint[6,2] * totalsumofwgt)
			gen c`j'subq4    = (sumwgt > qpoint[7,1] * totalsumofwgt  & sumwgt <= qpoint[7,2] * totalsumofwgt)
			gen c`j'subq5    = (sumwgt > qpoint[8,1] * totalsumofwgt  & sumwgt <= qpoint[8,2] * totalsumofwgt)
			gen c`j'sub9095  = (sumwgt > qpoint[9,1] * totalsumofwgt  & sumwgt <= qpoint[9,2] * totalsumofwgt)
			gen c`j'sub9599  = (sumwgt > qpoint[10,1] * totalsumofwgt & sumwgt <= qpoint[10,2] * totalsumofwgt)
			gen c`j'sub99100 = (sumwgt > qpoint[11,1] * totalsumofwgt & sumwgt <= qpoint[11,2] * totalsumofwgt)	
					
			drop sumwgt totalsumofwgt
			
			/*****************************************************************
			   Additional information in the text
			*****************************************************************/
			/* Share of disabled households */
			sum disabled [aw = wgt1], d
			local disabled = r(mean) * 100 
			noisily display "Share of disabled households : " %4.1f `disabled' " %" 
			sum disabled if occat == 4 [aw = wgt1], d
			local disablednonworkers = r(mean) * 100 
			noisily display "Share of disabled households nonworkers : " %4.1f `disablednonworkers' " %" 
			
			/* Retired widows */
			quietly : sum retiredwidow if c`j'sub0100 == 1 [aw = wgt1] 
			local retwidall = r(mean) * 100
			sum retiredwidow if c`j'sub01 == 1 [aw = wgt1] 
			local retwidpoorest = r(mean) * 100
			noisily display "Share of retired widows of poorest 1 %    : " %4.2f `retwidpoorest' " %" _newline /*
			*/ "Share of retired widows of all households : " %4.2f `retwidall' " %"
			
			/* Education installment */
			quietly : sum educationinstallment if c`j'sub01 == 1 [aw = wgt1] 
			local edudebtpoorest = r(mean) 
			quietly : sum debt if c`j'sub01 == 1 [aw = wgt1] 
			local debtpoorest = r(mean) 
			local sharedebt = `edudebtpoorest'/`debtpoorest' * 100
			
			noisily display "Education installment loans of poorest 1 %    : " %4.1f `edudebtpoorest' _newline /*
			*/ "Total debt and share of education debt " %4.1f `debtpoorest' " (" %4.1f `sharedebt' "% )" 
			
			/* *************************************************************** */
			local ii = 12
			foreach ss in `sslist' {
				/* Assets, debt, houses, and mortgage debt*/
				local ai = 1
				local numvarssp : word count `splist'
				foreach acvar in `splist' {
					sum networth if c`j'sub`ss' == 1 [aw = wgt1] 
					local cnetw = r(mean)
					sum `acvar' if c`j'sub`ss' == 1 [aw = wgt1] 
					local clev`ss'v`ai' = r(mean)
					local clevshare = qsize[`ii',1] * (`clev`ss'v`ai'' / `clev0100v`ai'')
					local ais = `ai' + `numvarssp'
					matrix table`tc8'[`ai',`ii'] = round(100 * `clev`ss'v`ai''/`cnetw',0.1) // round(1/1000 * `clev`ss'v`ai'',0.1)
					matrix table`tc8'[`ais',`ii'] = round(`clevshare',0.1)
					local ai = `ai' + 1
					}
				local ii = `ii' + 1
				if(`ii' > 12) {
					local ii = 1
					}		
				}
			/* Conditional averages and shares of total sample */
			local i = 1		
			foreach vvar in `varlist1' {
				local ii = 12
				foreach ss in `sslist' {
					/* METHOD 1 : Quantiles based on observed value at boundaries : problem is values are not increasing across quantiles*/
					/* METHOD 2 : Quantiles based on sum of weights (always strictly monotonically increasing) */
					/* Use lexiographic ordering to sort identical values in current variable */
					sum `vvar' if c`j'sub`ss' == 1 [aw = wgt1] 
					local pc`ss'a = r(mean)
					local pc`ss'share = qsize[`ii',1] * (`pc`ss'a' / `pc0100a')
													
					matrix table`tc'[`i',`ii']  = round(1/1000 * `pc`ss'a',0.1)
					matrix table`tc'x[`i',`ii'] = `pc`ss'a' 
					matrix table`tc1'[`i',`ii'] = round(`pc`ss'share',0.1)
					
					/* Total income for income shares */
					sum income if c`j'sub`ss' == 1 [aw = wgt1] 
					local ti`ss' = r(mean)
					local ii = `ii' + 1
					if(`ii' > 12) {
						local ii = 1
						}
					}
					local i = `i' + 1
				} /* end of i loop */
				
				
				/* Income shares */
				local ici = 1
				foreach ivar in `inclist' {
					local ii = 12
					foreach ss in `sslist' {
						sum `ivar'income if c`j'sub`ss' == 1 [aw = wgt1] 
						local is`ss' = r(mean)/abs(`ti`ss'')
						matrix table`tc2'[`ici',`ii'] = round(100 * `is`ss'',0.1)
						local ii = `ii' + 1
						if(`ii' > 12) {
							local ii = 1
							}
						} /* end of ss loop */
					local ici = `ici' + 1
					} /* end of ici loop */			
				
				/* Total sum of weights */
				local ii = 12
				foreach ss in `sslist' {
					sum age if c`j'sub`ss' == 1 [aw = wgt1] 
					local totsum`ss' = r(sum_w)
					local meanage`ss' = r(mean)
					local ii = `ii' + 1
					if(`ii' > 12) {
						local ii = 1
						}
					} /* end of ss loop */
				
				local tabc = `tc3'
				/* Coarse education partition */
				//foreach catvar in "agecl" "educl" "occat" {
				/* Coarse education partition */
				foreach catvar in "agecl" "educl_head" "occat" {
					/* Number of categories */
					local ncat = rowsof(table`tabc')
					forvalues ac = 1(1)`ncat' {
						local ii = 12
						foreach ss in `sslist' {
							sum `cvar' if c`j'sub`ss' == 1 & `catvar' == `ac' [aw = wgt1] 
							local numcat`ss' = r(sum_w)/`totsum`ss''
							matrix table`tabc'[`ac',`ii']  = round(100 * `numcat`ss'', 0.1)
							matrix table`tc3'[5,`ii']  = round(`meanage`ss'', 0.1)
							local ii = `ii' + 1
							if(`ii' > 12) {
								local ii = 1
								}
							} /* end of ss loop */
						/* Disabled as subgroup of the non-workers */
						if (`ac' == `ncat' - 1 & "`catvar'" == "occat") {
							local ac1 = `ac' + 1
							local ii = 12
							foreach ss in `sslist' {
								sum `cvar' if c`j'sub`ss' == 1 & `catvar' == `ac' & disabled == 1 [aw = wgt1] 
								local numcat`ss' = r(sum_w)/`totsum`ss''
								matrix table`tabc'[`ac1',`ii']  = round(100 * `numcat`ss'', 0.1)
								local ii = `ii' + 1
								if(`ii' > 12) {
									local ii = 1
									}
								} /* end of ss loop */
							continue, break
							} /* endo of ac if */
						} /* end of ac loop */
						local tabc = `tabc ' + 1
					} /* End of catvar loop */
					
				/* Marital status */
				forvalues ac = 1(1)3 {
						local ii = 12
						foreach ss in `sslist' {
							sum `cvar' if c`j'sub`ss' == 1 & marital == `ac' [aw = wgt1] 
							local numcat`ss' = r(sum_w)/`totsum`ss''
							matrix table`tc6'[`ac',`ii']  = round(100 * `numcat`ss'', 0.1)
							sum familysize if c`j'sub`ss' == 1 [aw = wgt1] 
							matrix table`tc6'[4,`ii']  = round(r(mean), 0.01)
							local ii = `ii' + 1
							if(`ii' > 12) {
								local ii = 1
								}
							} /* end of ss loop */
						} /* end of ac loop */
						
				/* Marital status excluding retired widows*/		
				forvalues ac = 2(1)3 {
					local ii = 12
					foreach ss in `sslist' {
						sum `cvar' if c`j'sub`ss' == 1 & marital == `ac' & retiredwidow ~= 1 [aw = wgt1] 
							local numcat`ss' = r(sum_w)/`totsum`ss''
							local cr = `ac' -1
							matrix table`tc7'[`cr',`ii']  = round(100 * `numcat`ss'', 0.1)
							local ii = `ii' + 1
							if(`ii' > 12) {
								local ii = 1
								}
							} /* end of ss loop */
						} /* end of ac loop */		
						
				/* Histograms for bottom 95% and top 5% of the distribution */
				* bottom 95%
				quietly : sum `cvar' if c`j'sub9599 == 0 & c`j'sub99100 == 0 [aw = wgt1]
		        local minc = r(mean)
	            local xtitle "Household `cvar'"
				histogram `cvar' if `cvar' >= - 0.5 * abs(`minc') & `cvar' <= 5 * abs(`minc') & c`j'sub9599 == 0 & c`j'sub99100 == 0 [fw = fwt], bin(250) percent ///
				xtitle("`xtitle'")
		        local figname = "`cvar'"
		        graph export "${figdir}`figname'distribution`y'_b95.eps", as(eps) replace
				* top 5%
				quietly : sum `cvar' if c`j'sub9599 == 1 | c`j'sub99100 == 1 [aw = wgt1]
		        local minc = r(mean)
				histogram `cvar' if `cvar' >= - 0.5 * abs(`minc') & `cvar' <= 5 * abs(`minc') & c`j'sub9599 == 1 | c`j'sub99100 == 1 [fw = fwt], bin(250) percent ///
				xtitle("`xtitle'")
		        graph export "${figdir}`figname'distribution`y'_t5.eps", as(eps) replace
				
			} /* End of j loop */
	  } /* End of quietly */

	/* Show tables */
	//matrix list table1
	matrix table1_`y' = table1
	frmttable using "${tabdir}table${tq}_`y'", statmat(table1) tex $basefont $titlfont vlines(000001000010000) replace $coljust $format ///
	title("Table $tq: Quantiles of the `y' Earnings, Income, and Wealth Distributions (`y' USD)") ///
	rtitles("Earnings"\"Income"\"Wealth")
	if(`y' == $minyear) {
	    putexcel set "${resdir}table${tq}", sheet("`y'", replace) replace 
		putexcel A1 = matrix(table1_`y'), names 
	}
	else {
		putexcel set "${resdir}table${tq}", sheet("`y'", replace) modify 
		putexcel A1 = matrix(table1_`y'), names 
	}
	
	//matrix list table2
	matrix table2_`y' = table2[1..3,1...] \ table2[5..6,1...] \ table2[4,1...] \ table2[7..8,1...] // reorder table2

	frmttable using "${tabdir}table${tcs}_`y'", statmat(table2) tex $basefont $titlfont hlines(1100100001) replace $coljust $format title("Table $tcs: Concentration and Skewness of the Distributions for `y'") ///
	rtitles("Coefficient of Variation"\"Variance of logs"\"Gini Indices"\"Location of the Mean"\"Mean to Median Ratio"\"99-50 Ratio"\"90-50 Ratio"\"50-30 Ratio")
	if(`y' == $minyear) {
		putexcel set "${resdir}table${tcs}", sheet("`y'", replace) replace 
		putexcel A1 = matrix(table2_`y'), names 
	}
	else {
		putexcel set "${resdir}table${tcs}", sheet("`y'", replace) modify 
		putexcel A1 = matrix(table2_`y'), names 
	}
	
	/* income correlation */
	correlate earnings income networth laborincome capitalincome businessincome transferincome [aw = wgt1]
	matrix table3_`y' = r(C)
	forvalues ri = 1(1)7 {
		forvalues rj = 1(1)7 {
			local cval = table3_`y'[`ri',`rj']
			matrix table3_`y'[`ri',`rj'] = round(`cval',0.01)
			}
		}
	matrix htable3_`y' = J(7,7,.) // store lower triangle in matrix to be used for frmttable 
	forvalues r = 1/7{
	    forvalues c = 1/7{
		    if `r' >= `c'{ 
		        matrix htable3_`y'[`r',`c'] = table3_`y'[`r',`c'] 
			}
		}
	}
	frmttable using "${tabdir}table${tcc}_`y'", statmat(htable3_`y') tex $basefont $titlfont vlines(01{0}) replace $coljust $format title("Table $tcc: Correlation Coefficients of Earnings, Income, and Wealth in `y'") ///
	rtitles("Earnings"\"Income"\"Networth"\"Labor Inc."\"Capital Inc."\"Business Inc."\"Transfer Inc.") ctitles("","Earnings","Income","Networth","Labor Inc.","Capital Inc.","Business Inc.","Transfer Inc.")
	if(`y' == $minyear) {
		putexcel set "${resdir}table${tcc}", sheet("`y'", replace) replace 
		putexcel A1 = matrix(table3_`y'), names 
	}
	else {
		putexcel set "${resdir}table${tcc}", sheet("`y'", replace) modify 
		putexcel A1 = matrix(table3_`y'), names 
	}
				
    local tp = $tp 
	forvalues j = 40(10)60 {
		local ft = `j' + 1
		local lt = `j' + 9
		forvalues i = `ft'(1)`lt' {
			matrix list table`i'
			matrix table`i'_`y' = table`i'
			if(`j' == 40) {
				local pvar = "Earnings" 
				}
			else if(`j' == 50){
				local pvar = "Income" 
				}
			else if(`j' == 60){
				local pvar = "Wealth" 
				}
			if `i' - `j' == 1{
				matrix etable`i' = (.,.,.,.,.,.,.,.,.,.,.,.) \ table`i'
			    frmttable using "${tabdir}table`tp'_`y'", statmat(etable`i') tex $basefont $titlfont vlines(01001000010010) replace $coljust $format ///
				title("Table `tp': `pvar' Partition of the `y' Sample") rtitles("\textbf{Averages (x $10^3$ USD):}"\"Earnings"\"Income"\"Wealth") ///
				ctitles("","\textbf{Bottom(\%)}","","","\textbf{Quintiles}","","","","","\textbf{Top(\%)}","","","\textbf{All}"\"","0-1","1-5","5-10","1st","2nd","3rd","4th","5th","90-95","95-99","99-100","0-100") nodisplay
			}
			else if `i' - `j' == 2{
				matrix etable`i' = (.,.,.,.,.,.,.,.,.,.,.,.) \ table`i'
			    frmttable using "${tabdir}table`tp'_`y'", statmat(etable`i') tex $basefont vlines(01001000010010) replace $coljust $format rtitles("\textbf{Share of Sample (\%):}"\"Earnings"\"Income"\"Wealth") ///
				append nodisplay
			}
			else if `i' - `j' == 3{
				local ii = `j' + 9 
				matrix etable`ii' = (.,.,.,.,.,.,.,.,.,.,.,.) \ table`ii'[1..5,1...]
			    frmttable using "${tabdir}table`tp'_`y'", statmat(etable`ii') tex $basefont vlines(01001000010010) replace $coljust $format rtitles("\textbf{Asset Classes (\%):}"\"Housing \& Cars" ///
				\"Business \& Nonfinancial"\"Financial Assets"\"Collaterized Debt"\"Uncollateralized Debt") append nodisplay
				matrix etable`ii' = (.,.,.,.,.,.,.,.,.,.,.,.) \ table`ii'[6...,1...]
			    frmttable using "${tabdir}table`tp'_`y'", statmat(etable`ii') tex $basefont vlines(01001000010010) replace $coljust $format rtitles("\textbf{Share of Sample (\%):}"\"Housing \& Cars" ///
				\"Business \& Nonfinancial"\"Financial Assets"\"Collaterized Debt"\"Uncollateralized Debt") append nodisplay
			}
			else if `i' - `j' == 4{
				local ii = `j' + 3
				matrix etable`ii' = (.,.,.,.,.,.,.,.,.,.,.,.) \ table`ii'
				frmttable using "${tabdir}table`tp'_`y'", statmat(etable`ii') tex $basefont vlines(01001000010010) replace $coljust $format rtitles("\textbf{Income Sources (\%):}"\"Labor" ///
				\"Capital"\"Business"\"Transfer"\"Other") append nodisplay
			}
			else if `i' - `j' == 5{
				local ii = `j' + 4
				matrix etable`ii' = (.,.,.,.,.,.,.,.,.,.,.,.) \ table`ii'
				frmttable using "${tabdir}table`tp'_`y'", statmat(etable`ii') tex $basefont vlines(01001000010010) replace $coljust $format rtitles("\textbf{Age (\%):}"\"Under 31" ///
				\"31-45"\"46-65"\"Over 65"\"Average (Years)") append nodisplay
			}
			else if `i' - `j' == 6{
				local ii = `j' + 5
				matrix etable`ii' = (.,.,.,.,.,.,.,.,.,.,.,.) \ table`ii'
				frmttable using "${tabdir}table`tp'_`y'", statmat(etable`ii') tex $basefont vlines(01001000010010) replace $coljust $format rtitles("\textbf{Education (\%):}"\"Dropouts" ///
				\"High-School"\"Some-College"\"College") append nodisplay
			}
			else if `i' - `j' == 7{
				local ii = `j' + 6
				matrix etable`ii' = (.,.,.,.,.,.,.,.,.,.,.,.) \ table`ii'
				frmttable using "${tabdir}table`tp'_`y'", statmat(etable`ii') tex $basefont vlines(01001000010010) replace $coljust $format rtitles("\textbf{Employment Status (\%):}"\"Workers" ///
				\"Self-Employed"\"Retired"\"Non-Workers"\"Disabled") append nodisplay
			}
			else if `i' - `j' == 8{
				local ii = `j' + 7
				matrix etable`ii' = (.,.,.,.,.,.,.,.,.,.,.,.) \ table`ii'
				frmttable using "${tabdir}table`tp'_`y'", statmat(etable`ii') tex $basefont vlines(01001000010010) replace $coljust $format rtitles("\textbf{Marital Status (\%):}"\"Married" ///
				\"Single w/ Dependents"\"Single w/o Dependents"\"Family Size") append nodisplay
			}
			else{
				local ii = `j' + 8
				matrix etable`ii' = (.,.,.,.,.,.,.,.,.,.,.,.) \ table`ii'
				frmttable using "${tabdir}table`tp'_`y'", statmat(etable`ii') tex $basefont vlines(01001000010010) replace $coljust $format rtitles("\textit{\textbf{Excl. Retired Widows}}" ///
				\"Single w/ Dependents"\"Single w/o Dependents") multicol(1,2,3;1,5,5;1,10,3) append nodisplay
			}
			local k = `i' - `j'
			if(`y' == $minyear) {
			    putexcel set "${resdir}table`tp'_`k'", sheet("`y'", replace) replace 
				putexcel A1 = matrix(table`i'_`y'), names 
				}
			else {
			    putexcel set "${resdir}table`tp'_`k'", sheet("`y'", replace) modify 
				putexcel A1 = matrix(table`i'_`y'), names 
				}
		}
		local ++tp
	}
	local tpp = $tpp
	forvalues jj = 1(1)4 {
		if(`jj' == 1) {
			local pvar = "Age" 
			local rtitle = `"rtitle("-25"\"26-30"\"31-35"\"36-40"\"41-45"\"46-50"\"51-55"\"56-60"\"61-65"\"66+"\"Total")"'
			}
		else if(`jj' == 2){
			local pvar = "Education" 
			local rtitle = `"rtitle("Dropouts"\"High-School"\"Some-College"\"College"\"Total")"'
			}
		else if(`jj' == 3){
			local pvar = "Employment" 
			local rtitle = `"rtitle("Workers"\"Self-Employed"\"Retired"\"Non-Workers"\"\; Disabled"\"Total")"'
			}
		else if(`jj' == 4){
			local pvar = "Marital Status" 
			local rtitle = `"rtitle("Married"\"Single"\"Single w/ Dep."\"\; Male"\"\; Female"\"Single w/o Dep."\"\; Male"\"\; Female"\"Retired Widows"\"Total")"'
			}
		forvalues j = 1(1)5 {
			matrix list table1`jj'`j'
			matrix table1`jj'`j'_`y' = table1`jj'`j'
			matrix itable1`jj'`j'_`y' =  table1`jj'`j'_`y''
			if `j' == 1{
			    frmttable using "${tabdir}table`tpp'_`y'", statmat(table1`jj'`j'_`y') tex $basefont $titlfont hlines(101{0}11)replace $coljust $format ///
				title("Table `tpp': `pvar' Partition of the `y' Sample") `rtitle' ctitles("","\textbf{Averages (x $10^3$ USD)}","",""\"\textbf{`pvar'}","E$^a$","Y$^b$","W$^c$") ///
				nodisplay multicol(1,2,3)
			}
			if `j' == 2{
			    frmttable using "${tabdir}table`tpp'_`y'", statmat(table1`jj'`j'_`y') tex $basefont $titlfont hlines(101{0}11) replace $coljust $format ///
				`rtitle' ctitles("","\textbf{Income Sources (\%)}","","","",""\"","L$^d$","K$^e$","B$^f$","Z$^g$","O$^h$") ///
				merge nodisplay multicol(1,2,3;1,5,5)
			}
            if `j' == 3{
	            frmttable using "${tabdir}table`tpp'_`y'", statmat(table1`jj'`j'_`y') tex $basefont $titlfont hlines(101{0}11) replace $coljust $format ///
			    `rtitle' ctitles("","\textbf{Gini Coefficient}","",""\"","E$^a$","Y$^b$","W$^c$") merge nodisplay ///
				multicol(1,2,3;1,5,5;1,10,3)
			}
			if `j' == 4{
			    frmttable using "${tabdir}table`tpp'_`y'", statmat(table1`jj'`j'_`y') tex $basefont $titlfont hlines(101{0}11) replace $coljust $format ///
				`rtitle' ctitles("","\textbf{Coeff. of Variation}","",""\"","E$^a$","Y$^b$","W$^c$") merge nodisplay ///
				multicol(1,2,3;1,5,5;1,10,3;1,13,3) 
			}
			if `j' == 5{
			    frmttable using "${tabdir}table`tpp'_`y'", statmat(table1`jj'`j'_`y') tex $basefont $titlfont hlines(101{0}11) replace $coljust $format ///
				`rtitle' ctitles("","\textbf{Share \& Size}",""\"","H(\%)$^i$","Size$^j$") merge nodisplay ///
				note("Note: $^a$ Earnings; $^b$ Income; $^c$ Wealth; $^d$ Labor; $^e$ Capital; $^f$ Business; $^g$ Transfers; $^h$ Other; $^i$ Percentage of households of each type;" ///
				"$^j$ Average number of persons per primary economic unit.") multicol(1,2,3;1,5,5;1,10,3;1,13,3;1,16,2) vlines(0100100001001001{0})
			}
			if(`y' == $minyear) {
			    putexcel set "${resdir}table`tpp'_`j'", sheet("`y'", replace) replace 
				putexcel A1 = matrix(table1`jj'`j'_`y'), names 
				}
			else {
			    putexcel set "${resdir}table`tpp'_`j'", sheet("`y'", replace) modify 
				putexcel A1 = matrix(table1`jj'`j'_`y'), names 
				}
			
			}
			local ++tpp
		}
		
      /* Write additional tables for family/labor market status */
	  global y = `y' // pass local y to dofiles below 
	  run "${dodir}family_status.do"
	  run "${dodir}labor_status.do"
	  
	  /* Write additional tables for children along the wealth distribution */
	  run "${dodir}children_along_distribution.do"
	  
	  /* Write additional tables for regressions of income/wealth on industry/occupation */
	  run "${dodir}occat_industry_regressions.do"
	  
	  /* Draw bar charts for saving attitudes */
	  run "${dodir}saving_attitudes.do"
	  
} // end y loop

				
/* Write latex tables for document 
global precision = 0
global i = 1
run "${dodir}writelatextables.do"
global precision = 2
global i = 2
run "${dodir}writelatextables.do"

global precision = 1
forvalues j = 40(10)60 {
	local ft = `j' + 1
	local lt = `j' + 9
	forvalues ii = `ft'(1)`lt' {
		global i = `ii'
		run "${dodir}writelatextables.do"
		}
	}
*/ 

/* Write time trend table: Version 1 
local rtitles = `"rtitles("1989"\"1992"\"1995"\"1998"\"2001"\"2004"\"2007"\"2010"\"2013"\"2016"\"2019"\"2022")"'

matrix itimetrend1 = timetrend1[1...,2...]/1000
forvalues r = 1/12{
	forvalues c = 1/4{
	    matrix itimetrend1[`r',`c'] = round(itimetrend1[`r',`c'],0.01)
	}
}
frmttable using "${tabdir}table$ttt", statmat(itimetrend1) tex $basefont $titlfont replace $coljust title("Table $ttt: Time Trends \bigskip"\"(a): Averages, Coefficient of Variation, Variance of Logs") `rtitles' ///
ctitles("","\textbf{Averages (x $10^3$ USD)}","","",""\"\textbf{Year}","Earnings","Income","Wealth","NH Wealth$^a$") multicol(1,2,4) $format nodisplay 
putexcel set "${resdir}table${ttt}_1", sheet("${minyear}-${maxyear}", replace) replace 
putexcel A1 = matrix(timetrend1), colnames 

matrix itimetrend2_s1 = timetrend2_s1[1...,2...]
frmttable using "${tabdir}table$ttt", statmat(itimetrend2_s1) tex $basefont $titlfont replace $coljust `rtitles' multicol(1,2,4;1,6,4) $format ///
ctitles("","\textbf{Coeff. of Variation}","","",""\"","Earnings","Income","Wealth","NH Wealth$^a$") merge nodisplay
putexcel set "${resdir}table${ttt}_2", sheet("${minyear}-${maxyear}", replace) replace 
putexcel A1 = matrix(timetrend2_s1), colnames 

matrix itimetrend2_s2 = timetrend2_s2[1...,2...]
frmttable using "${tabdir}table$ttt", statmat(itimetrend2_s2) tex $basefont $titlfont replace $coljust `rtitles' multicol(1,2,4;1,6,4;1,10,4) $format ///
ctitles("","\textbf{Variance of Logs}","","",""\"","Earnings","Income","Wealth","NH Wealth$^a$") merge nodisplay vlines(0100010001{0})
putexcel set "${resdir}table${ttt}_3", sheet("${minyear}-${maxyear}", replace) replace 
putexcel A1 = matrix(timetrend2_s2), colnames 

matrix itimetrend2_s3 = timetrend2_s3[1...,2...]
frmttable, statmat(itimetrend2_s3) tex $basefont $titlfont replace $coljust title("(b): Gini Coefficient, 99-50-Ratio, Location of the Mean") `rtitles' multicol(1,2,4) ///
$format ctitles("","\textbf{Gini Coeff.}","","",""\"\textbf{Year}","Earnings","Income","Wealth","NH Wealth$^a$") nodisplay 
putexcel set "${resdir}table${ttt}_4", sheet("${minyear}-${maxyear}", replace) replace 
putexcel A1 = matrix(timetrend2_s3), colnames 

matrix itimetrend2_s4 = timetrend2_s4[1...,2...]
frmttable, statmat(itimetrend2_s4) tex $basefont $titlfont replace $coljust `rtitles' multicol(1,2,4;1,6,4) $format ///
ctitles("","\textbf{99-50-Ratio}","","",""\"","Earnings","Income","Wealth","NH Wealth$^a$") nodisplay merge 
putexcel set "${resdir}table${ttt}_5", sheet("${minyear}-${maxyear}", replace) replace 
putexcel A1 = matrix(timetrend2_s4), colnames 

matrix itimetrend2_s5 = timetrend2_s5[1...,2...]
frmttable using "${tabdir}table$ttt", statmat(itimetrend2_s5) tex $basefont $titlfont replace $coljust `rtitles' multicol(1,2,4;1,6,4;1,10,4) $format ///
ctitles("","\textbf{Location of the Mean}","","",""\"","Earnings","Income","Wealth","NH Wealth$^a$") nodisplay merge addtable vlines(0100010001{0})
putexcel set "${resdir}table${ttt}_6", sheet("${minyear}-${maxyear}", replace) replace 
putexcel A1 = matrix(timetrend2_s5), colnames 

matrix itimetrend2_s6 = timetrend2_s6[1...,2...]
frmttable, statmat(itimetrend2_s6) tex $basefont $titlfont replace $coljust title("(c): Mean-to-Median-Ratio, 90-50-Ratio, 50-30-Ratio") `rtitles' multicol(1,2,4) ///
$format ctitles("","\textbf{Mean-to-Median Ratio}","","",""\"\textbf{Year}","Earnings","Income","Wealth","NH Wealth$^a$") nodisplay  addtable
putexcel set "${resdir}table${ttt}_7", sheet("${minyear}-${maxyear}", replace) replace 
putexcel A1 = matrix(timetrend2_s6), colnames 

matrix itimetrend2_s7 = timetrend2_s7[1...,2...]
frmttable, statmat(itimetrend2_s7) tex $basefont $titlfont replace $coljust `rtitles' multicol(1,2,4;1,6,4) $format ///
ctitles("","\textbf{90-50-Ratio}","","",""\"","Earnings","Income","Wealth","NH Wealth$^a$") nodisplay merge 
putexcel set "${resdir}table${ttt}_8", sheet("${minyear}-${maxyear}", replace) replace 
putexcel A1 = matrix(timetrend2_s7), colnames 

matrix itimetrend2_s8 = timetrend2_s8[1...,2...]
frmttable using "${tabdir}table$ttt", statmat(itimetrend2_s8) tex $basefont $titlfont replace $coljust `rtitles' multicol(1,2,4;1,6,4;1,10,4) $format ///
ctitles("","\textbf{50-30-Ratio}","","",""\"","Earnings","Income","Wealth","NH Wealth$^a$") nodisplay merge addtable vlines(0100010001{0})
putexcel set "${resdir}table${ttt}_9", sheet("${minyear}-${maxyear}", replace) replace 
putexcel A1 = matrix(timetrend2_s8), colnames 

matrix itimetrend3 = timetrend3[1...,2...] / 1000
forvalues r = 1/12{
	forvalues c = 1/9{
	    matrix itimetrend3[`r',`c'] = round(itimetrend3[`r',`c'],0.01)
	}
}
frmttable using "${tabdir}table$ttt", statmat(itimetrend3) tex $basefont $titlfont replace $coljust `rtitles' multicol(1,2,3;1,5,3;1,8,3) $format ///
ctitles("","\textbf{30th Percentile}","","","\textbf{50th Percentile}","","","\textbf{90th Percentile}","",""\"\textbf{Year}","Earnings","Income","Wealth","Earnings","Income","Wealth" ///
,"Earnings","Income","Wealth") nodisplay addtable vlines(01001001{0}) note("Note: $^a$ Nonhousing Wealth.") title("(d): 30th, 50th, and 90th Percentile (x $10^3$ USD)") pretext("\clearpage")
putexcel set "${resdir}table${ttt}_10", sheet("${minyear}-${maxyear}", replace) replace 
putexcel A1 = matrix(timetrend3), colnames 
*/

/* Write time trend table: Version 2 */
local rtitles = `"rtitles("1989"\"1992"\"1995"\"1998"\"2001"\"2004"\"2007"\"2010"\"2013"\"2016"\"2019"\"2022")"'

* Levels 
matrix itimetrend1 = timetrend1[1...,2..4]/1000
forvalues r = 1/12{
	forvalues c = 1/3{
	    matrix itimetrend1[`r',`c'] = round(itimetrend1[`r',`c'],0.1)
	}
}
matrix iitimetrend1 = timetrend1[1...,1..4]

matrix itimetrend3 = timetrend3[1...,2...] / 1000
forvalues r = 1/12{
	forvalues c = 1/9{
	    matrix itimetrend3[`r',`c'] = round(itimetrend3[`r',`c'],0.1)
	}
}

frmttable, statmat(itimetrend1) tex $basefont $titlfont replace $coljust title("Table $ttt: Time Trends \bigskip"\"(a): Levels") `rtitles' ///
ctitles("","\textbf{Averages (x $10^3$ USD)}","",""\"\textbf{Year}","Earnings","Income","Wealth") multicol(1,2,3) $format nodisplay 
putexcel set "${resdir}table${ttt}", sheet("Averages", replace) replace 
putexcel A1 = matrix(iitimetrend1), colnames 

frmttable using "${tabdir}table$ttt", statmat(itimetrend3) tex $basefont $titlfont replace $coljust `rtitles' multicol(1,2,3;1,5,3;1,8,3;1,11,3) $format ///
ctitles("","\textbf{30th Percentile}","","","\textbf{50th Percentile}","","","\textbf{90th Percentile}","",""\"\textbf{Year}","Earnings","Income","Wealth","Earnings","Income","Wealth" ///
,"Earnings","Income","Wealth") nodisplay vlines(01001001001{0}) merge  
putexcel set "${resdir}table${ttt}", sheet("Percentiles", replace) modify 
putexcel A1 = matrix(timetrend3), colnames 

* Inequality 
matrix itimetrend2_s3 = timetrend2_s3[1...,2..4]
matrix iitimetrend2_s3 = timetrend2_s3[1...,1..4]
frmttable, statmat(itimetrend2_s3) tex $basefont $titlfont replace $coljust title("(b): Inequality") `rtitles' multicol(1,2,3) ///
$format ctitles("","\textbf{Gini Coeff.}","",""\"\textbf{Year}","Earnings","Income","Wealth") nodisplay 
putexcel set "${resdir}table${ttt}", sheet("Gini Coefficient", replace) modify 
putexcel A1 = matrix(iitimetrend2_s3), colnames 

matrix itimetrend2_s1 = timetrend2_s1[1...,2..4]
matrix iitimetrend2_s1 = timetrend2_s1[1...,1..4]
frmttable, statmat(itimetrend2_s1) tex $basefont $titlfont replace $coljust `rtitles' multicol(1,2,3;1,3,3) $format ///
ctitles("","\textbf{Coeff. of Variation}","",""\"","Earnings","Income","Wealth") merge nodisplay
putexcel set "${resdir}table${ttt}", sheet("Coefficient of Variation", replace) modify 
putexcel A1 = matrix(iitimetrend2_s1), colnames 

matrix itimetrend2_s2 = timetrend2_s2[1...,2..4]
matrix iitimetrend2_s2 = timetrend2_s2[1...,1..4]
frmttable using "${tabdir}table$ttt", statmat(itimetrend2_s2) tex $basefont $titlfont replace $coljust `rtitles' multicol(1,2,3;1,5,3;1,8,3) $format ///
ctitles("","\textbf{Variance of Logs}","",""\"","Earnings","Income","Wealth") merge nodisplay vlines(01001001{0}) addtable
putexcel set "${resdir}table${ttt}", sheet("Variance of Logs", replace) modify 
putexcel A1 = matrix(iitimetrend2_s2), colnames 

* Shape of the distribution 
matrix itimetrend2_s6 = timetrend2_s6[1...,2..4]
matrix iitimetrend2_s6 = timetrend2_s6[1...,1..4]
frmttable, statmat(itimetrend2_s6) tex $basefont $titlfont replace $coljust title("(c): Shape of the distribution") `rtitles' multicol(1,2,3) ///
$format ctitles("","\textbf{Mean-to-Median Ratio}","",""\"\textbf{Year}","Earnings","Income","Wealth") nodisplay
putexcel set "${resdir}table${ttt}", sheet("Mean to Median Ratio", replace) modify 
putexcel A1 = matrix(iitimetrend2_s6), colnames 

matrix itimetrend2_s5 = timetrend2_s5[1...,2..4]
matrix iitimetrend2_s5 = timetrend2_s5[1...,1..4]
frmttable, statmat(itimetrend2_s5) tex $basefont $titlfont replace $coljust `rtitles' multicol(1,2,3;1,5,3) $format ///
ctitles("","\textbf{Location of the Mean}","",""\"","Earnings","Income","Wealth") nodisplay merge 
putexcel set "${resdir}table${ttt}", sheet("Location of the Mean", replace) modify 
putexcel A1 = matrix(iitimetrend2_s5), colnames 

matrix itimetrend2_s4 = timetrend2_s4[1...,2..4]
matrix iitimetrend2_s4 = timetrend2_s4[1...,1..4]
frmttable, statmat(itimetrend2_s4) tex $basefont $titlfont replace $coljust `rtitles' multicol(1,2,3;1,5,3;1,8,3) $format ///
ctitles("","\textbf{99-50-Ratio}","",""\"","Earnings","Income","Wealth") nodisplay merge 
putexcel set "${resdir}table${ttt}", sheet("99-50-Ratio", replace) modify 
putexcel A1 = matrix(iitimetrend2_s4), colnames 

matrix itimetrend2_s7 = timetrend2_s7[1...,2..4]
matrix iitimetrend2_s7 = timetrend2_s7[1...,1..4]
frmttable, statmat(itimetrend2_s7) tex $basefont $titlfont replace $coljust `rtitles' multicol(1,2,3;1,5,3;1,8,3;1,11,3) $format ///
ctitles("","\textbf{90-50-Ratio}","",""\"","Earnings","Income","Wealth") nodisplay merge 
putexcel set "${resdir}table${ttt}", sheet("90-50-Ratio", replace) modify 
putexcel A1 = matrix(iitimetrend2_s7), colnames 

matrix itimetrend2_s8 = timetrend2_s8[1...,2..4]
matrix iitimetrend2_s8 = timetrend2_s8[1...,1..4]
frmttable using "${tabdir}table$ttt", statmat(itimetrend2_s8) tex $basefont $titlfont replace $coljust `rtitles' multicol(1,2,3;1,5,3;1,8,3;1,11,3;1,14,3) $format ///
ctitles("","\textbf{50-30-Ratio}","",""\"","Earnings","Income","Wealth") nodisplay merge addtable vlines(01001001001001{0})
putexcel set "${resdir}table${ttt}", sheet("50-30-Ratio", replace) modify 
putexcel A1 = matrix(iitimetrend2_s8), colnames 


/* Store all results to matlab */	
preserve
clear
matwrite using "${resdir}allresults.mat", replace 
restore	

forvalues y = 1989(3)2022 { 
	preserve
	clear
	/* Plot age profiles */
	svmat table111_`y', names("mean")
	svmat table112_`y', names("source")
	svmat table113_`y', names("gini")
	svmat table114_`y', names("cv")
	egen midage = seq()
	gen meanearn = mean1[_N]
	gen meaninc = mean2[_N]
	gen meanwealth = mean3[_N]
	replace mean1 = mean1/meanearn 
	replace mean2 = mean2/meaninc 
	replace mean3 = mean3/meanwealth 
	drop if _n == _N
	twoway connect mean1 midage, msymbol(o)  msize(vlarge) || connect mean2 midage, msymbol(S)  msize(medium) || connect mean3 midage , msymbol(D)  msize(medium) legend(label(1 "Earnings") label(2 "Income") label(3 "Wealth")) /*
	*/ xlabel( 1 "-25" 2 "26-30" 3 "31-35" 4 "36-40" 5 "41-45" 6 "46-50" 7 "51-55" 8 "56-60" 9 "61-65" 10 "66+" ) xtitle("Age") name("meanprofiles", replace)
	graph export "${figdir}meanlifecycle`y'.eps", as(eps) replace
	
	graph bar source1 source2 source3 source4 , /*
	*/ over(midage, relabel( 1 "-25" 2 "26-30" 3 "31-35" 4 "36-40" 5 "41-45" 6 "46-50" 7 "51-55" 8 "56-60" 9 "61-65" 10 "66+" )) /*
	*/ legend(label(1 "labor") label(2 "capital") label(3 "business") label(4 "transfer")) name("sourceprofiles", replace)
	graph export "${figdir}sourcelifecycle`y'.eps", as(eps) replace
	
	twoway connect gini1 midage , msymbol(o)  msize(vlarge) || connect gini2 midage , msymbol(S)  msize(medium) || connect gini3 midage , msymbol(D)  msize(medium) legend(label(1 "Earnings") label(2 "Income") label(3 "Wealth")) /*
	*/ xlabel( 1 "-25" 2 "26-30" 3 "31-35" 4 "36-40" 5 "41-45" 6 "46-50" 7 "51-55" 8 "56-60" 9 "61-65" 10 "66+" ) xtitle("Age") name("giniprofiles", replace)
	graph export "${figdir}ginilifecycle`y'.eps", as(eps) replace

	twoway connect cv1 midage , msymbol(o)  msize(vlarge) || connect cv2 midage , msymbol(S)  msize(medium) || connect cv3 midage , msymbol(D)  msize(medium) legend(label(1 "Earnings") label(2 "Income") label(3 "Wealth")) /*
	*/ xlabel( 1 "-25" 2 "26-30" 3 "31-35" 4 "36-40" 5 "41-45" 6 "46-50" 7 "51-55" 8 "56-60" 9 "61-65" 10 "66+" ) xtitle("Age") name("cvprofiles", replace)
	graph export "${figdir}cvlifecycle`y'.eps", as(eps) replace

	
	restore
	}

log close
