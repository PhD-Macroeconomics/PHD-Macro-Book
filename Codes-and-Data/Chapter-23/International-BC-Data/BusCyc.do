clear all
cd "C:\Users\marin\Dropbox\MarinaFiles\ResearchPapers\TheBookLocal\InternationalChapter\DataIntMarina"
*import excel "C:\Users\marin\Dropbox\MarinaFiles\ResearchPapers\TheBookLocal\InternationalChapter\DataIntMarina\World_Development_Indicators_9_2024.xlsx", sheet("Data") firstrow allstring

import excel "C:\Users\marin\Dropbox\MarinaFiles\ResearchPapers\TheBookLocal\InternationalChapter\DataIntMarina\World_Development_Indicators_ALL_12_8.xlsx", sheet("Data") firstrow allstring


gen variable=""
replace variable="cy" if SeriesName=="Households and NPISHs final consumption expenditure (% of GDP)"
replace variable="y_p" if SeriesName=="GDP per capita, PPP (constant 2021 international $)"
replace variable="y_nom" if SeriesName=="GDP per capita (current LCU)"
replace variable="gy" if SeriesName=="General government final consumption expenditure (% of GDP)"
replace variable="my" if SeriesName=="Imports of goods and services (% of GDP)"
replace variable="xy" if SeriesName=="Exports of goods and services (% of GDP)"
replace variable="pop" if SeriesName=="Population, total"
replace variable="tt" if SeriesName=="Net barter terms of trade index (2015 = 100)"
replace variable="rer" if SeriesName=="Real effective exchange rate index (2010 = 100)"
replace variable="invy" if SeriesName=="Gross fixed capital formation (% of GDP)"
replace variable="CAy" if SeriesName=="Current account balance (% of GDP)"
replace variable="y" if SeriesName=="GDP per capita (constant LCU)"

*save DevelopedData.dta, replace
save AllData.dta, replace

 destring E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC AD AE AF AG AH AI AJ AK  AL AM AN AO AP AQ AR AS AT AU AV AW AX AY AZ BA BB BC BD BE BF BG BH BI BJ BK BL BM  BN BO BP, replace
*save DevelopedData.dta, replace


drop SeriesCode
sort variable CountryName 

save AllData.dta, replace




** reshape y_nom 
* nominal GDP: GDP per capita (current LCU)
* NY.GDP.PCAP.CN


clear all
use AllData.dta

keep if variable=="y_nom"

foreach v of var * {
    local lbl : var label `v'
    local lbl = strtoname("y_nom`lbl'")
    capture rename `v' `lbl'
}

rename y_nomCountry_Name Country_Name
rename y_nomCountry_Code Country_Code
rename y_nomSeries_Name Series_Name
drop y_nom

reshape long y_nom, i(Country_Name) j(year)

save y_nom.dta, replace


** reshape y_p
* GDP per capita: GDP per capita, PPP (constant 2021 international $)
* NY.GDP.PCAP.PP.KD


clear all
use AllData.dta

keep if variable=="y_p"

foreach v of var * {
    local lbl : var label `v'
    local lbl = strtoname("y_p`lbl'")
    capture rename `v' `lbl'
}

rename y_pCountry_Name Country_Name
rename y_pCountry_Code Country_Code
rename y_pSeries_Name Series_Name
drop y_p

reshape long y_p, i(Country_Name) j(year)

save y_p.dta, replace

** reshape invy
* Gross fixed capital formation (% of GDP)
* NE.GDI.FTOT.ZS


clear all
use AllData.dta

keep if variable=="invy"

foreach v of var * {
    local lbl : var label `v'
    local lbl = strtoname("invy`lbl'")
    capture rename `v' `lbl'
}

rename invyCountry_Name Country_Name
rename invyCountry_Code Country_Code
rename invySeries_Name Series_Name
drop invy

reshape long invy, i(Country_Name) j(year)


save invy.dta, replace


** reshape cy
* Households and NPISHs final consumption expenditure (% of GDP)
* NE.CON.PRVT.ZS

clear all
use AllData.dta

keep if variable=="cy"

foreach v of var * {
    local lbl : var label `v'
    local lbl = strtoname("cy`lbl'")
    capture rename `v' `lbl'
}

rename cyCountry_Name Country_Name
rename cyCountry_Code Country_Code
rename cySeries_Name Series_Name
drop cy

reshape long cy, i(Country_Name) j(year)

save cy.dta, replace


** reshape my
* Imports of goods and services (% of GDP)
* NE.IMP.GNFS.ZS

clear all
use AllData.dta

keep if variable=="my"

foreach v of var * {
    local lbl : var label `v'
    local lbl = strtoname("my`lbl'")
    capture rename `v' `lbl'
}

rename myCountry_Name Country_Name
rename myCountry_Code Country_Code
rename mySeries_Name Series_Name
drop my

reshape long my, i(Country_Name) j(year)

save my.dta, replace


** reshape xy
* Exports of goods and services (% of GDP)
* NE.EXP.GNFS.ZS


clear all
use AllData.dta

keep if variable=="xy"

foreach v of var * {
    local lbl : var label `v'
    local lbl = strtoname("xy`lbl'")
    capture rename `v' `lbl'
}

rename xyCountry_Name Country_Name
rename xyCountry_Code Country_Code
rename xySeries_Name Series_Name
drop xy

reshape long xy, i(Country_Name) j(year)


save xy.dta, replace


** reshape pop
* Population, total
* SP.POP.TOTL


clear all
use AllData.dta

keep if variable=="pop"

foreach v of var * {
    local lbl : var label `v'
    local lbl = strtoname("pop`lbl'")
    capture rename `v' `lbl'
}

rename popCountry_Name Country_Name
rename popCountry_Code Country_Code
rename popSeries_Name Series_Name
drop pop

reshape long pop, i(Country_Name) j(year)


save pop.dta, replace

** reshape gy
* General government final consumption expenditure (% of GDP)
* NE.CON.GOVT.ZS

clear all
use AllData.dta

keep if variable=="gy"

foreach v of var * {
    local lbl : var label `v'
    local lbl = strtoname("gy`lbl'")
    capture rename `v' `lbl'
}

rename gyCountry_Name Country_Name
rename gyCountry_Code Country_Code
rename gySeries_Name Series_Name
drop gy

reshape long gy, i(Country_Name) j(year)

save gy.dta, replace

** reshape tt
* Net barter terms of trade index (2015 = 100)
* TT.PRI.MRCH.XD.WD



clear all
use AllData.dta

keep if variable=="tt"

foreach v of var * {
    local lbl : var label `v'
    local lbl = strtoname("tt`lbl'")
    capture rename `v' `lbl'
}

rename ttCountry_Name Country_Name
rename ttCountry_Code Country_Code
rename ttSeries_Name Series_Name
drop tt

reshape long tt, i(Country_Name) j(year)


save tt.dta, replace

** reshape rer
* Real effective exchange rate index (2010 = 100)
* PX.REX.REER

clear all
use AllData.dta

keep if variable=="rer"

foreach v of var * {
    local lbl : var label `v'
    local lbl = strtoname("rer`lbl'")
    capture rename `v' `lbl'
}

rename rerCountry_Name Country_Name
rename rerCountry_Code Country_Code
rename rerSeries_Name Series_Name
drop rer

reshape long rer, i(Country_Name) j(year)


save rer.dta, replace


** reshape CAy
* Current account balance (% of GDP)
* BN.CAB.XOKA.GD.ZS


clear all
use AllData.dta

keep if variable=="CAy"

foreach v of var * {
    local lbl : var label `v'
    local lbl = strtoname("CAy`lbl'")
    capture rename `v' `lbl'
}

rename CAyCountry_Name Country_Name
rename CAyCountry_Code Country_Code
rename CAySeries_Name Series_Name
drop CAy

reshape long CAy, i(Country_Name) j(year)


save CAy.dta, replace




** reshape y
* GDP per capita (constant LCU)
* NY.GDP.PCAP.KN

clear all
use AllData.dta

keep if variable=="y"

foreach v of var * {
    local lbl : var label `v'
    local lbl = strtoname("y`lbl'")
    capture rename `v' `lbl'
}

rename yCountry_Name Country_Name
rename yCountry_Code Country_Code
rename ySeries_Name Series_Name
drop y

reshape long y, i(Country_Name) j(year)

save y.dta, replace

*********************
* merge results
********************


clear all

use cy.dta
drop Series_Name 

merge 1:1 Country_Name year using y.dta
drop Series_Name _merge

merge 1:1 Country_Name year using pop.dta
drop Series_Name _merge

merge 1:1 Country_Name year using gy.dta
drop Series_Name _merge

merge 1:1 Country_Name year using y_nom.dta
drop Series_Name _merge

merge 1:1 Country_Name year using y_p.dta
drop Series_Name _merge

merge 1:1 Country_Name year using invy.dta
drop Series_Name _merge

merge 1:1 Country_Name year using my.dta
drop Series_Name _merge

merge 1:1 Country_Name year using xy.dta
drop Series_Name _merge

merge 1:1 Country_Name year using tt.dta
drop Series_Name _merge

merge 1:1 Country_Name year using CAy.dta
drop Series_Name _merge

merge 1:1 Country_Name year using rer.dta
drop Series_Name _merge

save merged_ALL.dta, replace

local files cy.dta y.dta pop.dta y_nom.dta y_p.dta my.dta xy.dta gy.dta CAy.dta tt.dta rer.dta invy.dta
foreach file in `files' {
    erase `file'
}

clear all
use merged_ALL.dta
merge m:1 Country_Name using country_types.dta
drop _merge

save merged_ALL.dta, replace

********************************************************
*Clean strategy. Eliminate country if doesnt satisfy criterion of at 
*least 30 consecutive observations
********************************************************
clear all
use merged_ALL.dta

replace inv=. if inv<0
drop if inv==.

drop if Country_Name=="Bahamas, The"
drop if Country_Name=="Sierra Leone"
drop if Country_Name=="Ghana" & year==1975
drop if Country_Name=="Mali" & year<1985
drop if Country_Name=="Oman" & year<1990
drop if Country_Name=="Sri Lanka" & year<2009

local varlist CAy my cy xy invy gy y 

foreach var in `varlist' {
gen nonmissing_`var' = !missing(`var')
gen group_`var' = .


sort Country_Name year 
by Country_Name: replace group_`var' = cond(nonmissing_`var' == 1, sum(nonmissing_`var' == 0) + 1, .)

bysort Country_Name group_`var' (year): gen count_`var' = sum(nonmissing_`var')
drop if group_`var' ==.
by Country_Name group_`var'  : egen max_count_`var' = max(count_`var')
drop if max_count_`var'<30

drop count_`var' nonmissing_`var' group_`var'
}

drop if year<=1970

encode Country_Name, generate(ccode)


local varlist CA my cy xy inv gy y 
foreach var in `varlist' {
drop max_count_`var'

}

save cleaned_ALL.dta, replace


********************************************************
*compute HP-filter
********************************************************
clear all
use cleaned_ALL.dta


* generate variables in real per capita terms

gen c=cy*y
gen x=xy*y
gen g=gy*y
gen m=my*y
gen inv=invy*y
gen tby=xy-my
gen CA=CAy*y
gen open=xy+my
gen tb=x-m


* make this a panel
tsset ccode year

local varlist2 m c x inv g y 


*compute logs (here log makes a natural log)

foreach var in `varlist2' {
    gen ln_`var'=log(`var')


}

*compute transitory component of series using HP-filter

foreach i in ccode {
 	tsfilter hp hp_ln_y_`i' =	ln_y, smooth(100) 
	tsfilter hp hp_ln_c_`i' =	ln_c, smooth(100)
	tsfilter hp hp_ln_g_`i' =	ln_g, smooth(100)
	tsfilter hp hp_ln_m_`i' =	ln_m, smooth(100)
	tsfilter hp hp_ln_x_`i' =	ln_x, smooth(100)
	tsfilter hp hp_ln_inv_`i' =	ln_inv, smooth(100)
    tsfilter hp hp_y_`i' =	y, trend(trendy) smooth(100) 
	}

* divide Current Account and Trade Balance by the long-run component of income
* and HP-filter

gen CAdy=CA/trendy
gen tbdy=tb/trendy	

foreach i in ccode {
	tsfilter hp hp_CA_`i' =	CAdy, smooth(100)
	tsfilter hp hp_tb_`i' =	tbdy, smooth(100)
	
	tsfilter hp hp_CAy_`i' =	CAy, smooth(100)
	tsfilter hp hp_tby_`i' =	tby, smooth(100)	
}


save HPfiltered_Vars.dta, replace

********************************************************
* population weights
********************************************************
	
clear all
use HPfiltered_Vars.dta

keep ccode pop year type

*compute average population per country
sort ccode
by ccode: egen pop_c=mean(pop)

*keep only one obervation in the sample in he
bysort ccode: keep if _n==1

*compute total population for the whole sample
egen totpop=sum(pop_c)

*compute weights given full sample
gen country_weight=pop_c/totpop

*compute total population for D, U and EM (separately)

egen totpop_D=sum(pop_c)   if type=="D"
egen totpop_U=sum(pop_c)   if type=="U"
egen totpop_EM=sum(pop_c) if type=="EM"  

*compute weights for countries in D, U and EM (separately)
gen country_weight_D=pop_c/totpop_D
gen country_weight_U=pop_c/totpop_U
gen country_weight_EM=pop_c/totpop_EM


save country_weights.dta, replace


	
********************************************************
* Compute standard dviations of HP-filtered vars
********************************************************	
clear all
use HPfiltered_Vars.dta

*include country weights
merge m:1 ccode using country_weights.dta
drop _merge

	
sort ccode

foreach i in ccode {

by `i': egen sd_y_`i'=	sd(hp_ln_y_`i')
by `i': egen sd_c_`i'=	sd(hp_ln_c_`i') 
by `i': egen sd_m_`i'=	sd(hp_ln_m_`i') 
by `i': egen sd_x_`i'=	sd(hp_ln_x_`i')
by `i': egen sd_g_`i'=	sd(hp_ln_g_`i')
by `i': egen sd_inv_`i'=sd(hp_ln_inv_`i')
by `i': egen sd_CAy_`i'=sd(hp_CAy_`i')
by `i': egen sd_tby_`i'=sd(hp_tby_`i')
by `i': egen sd_CAdy_`i'=sd(hp_CA_`i')
by `i': egen sd_tbdy_`i'=sd(hp_tb_`i')
by `i': egen mean_open_`i'=		mean(open)
by `i': egen mean_tby_`i'=		mean(tby)
}

*express St Dev relative to y deviations

gen sdc_sdy=sd_c_ccode/sd_y_ccode
gen sdg_sdy=sd_g_ccode/sd_y_ccode
gen sdm_sdy=sd_m_ccode/sd_y_ccode
gen sdx_sdy=sd_x_ccode/sd_y_ccode
gen sdinv_sdy=sd_inv_ccode/sd_y_ccode
gen sdy=sd_y_ccode*100
gen sdCAdy=sd_CAdy_ccode
gen sdtbdy=sd_tbdy_ccode
gen sdCAy=sd_CAy_ccode
gen sdtby=sd_tby_ccode



********************************************************
* Compute Correlations
********************************************************


* Sort by the grouping variable
sort ccode

levelsof ccode, local(ccode)

local varlist hp_ln_y_ccode hp_ln_c_ccode hp_ln_m_ccode hp_ln_x_ccode hp_ln_g_ccode hp_ln_inv_ccode hp_CAy_ccode hp_tby_ccode hp_CA_ccode hp_tb_ccode

gen Corr_cons_y=.
gen Corr_m_y=.
gen Corr_x_y=.
gen Corr_g_y=.
gen Corr_tb_y=.
gen Corr_tby_y=.
gen Corr_CA_y=.
gen Corr_CAy_y=.
gen Corr_inv_y=.
gen Corr_y_y=.

foreach i in `ccode' {

corr hp_ln_y_ccode hp_ln_y_ccode if ccode == `i'
replace Corr_y_y = r(rho) if ccode == `i'

corr hp_ln_y_ccode hp_ln_c_ccode if ccode == `i'
replace Corr_cons_y = r(rho) if ccode == `i'

corr hp_ln_y_ccode hp_ln_m_ccode if ccode == `i'
replace Corr_m_y = r(rho) if ccode == `i'

corr hp_ln_y_ccode hp_ln_x_ccode if ccode == `i'
replace Corr_x_y = r(rho) if ccode == `i'

corr hp_ln_y_ccode  hp_ln_g_ccode  if ccode == `i'
replace Corr_g_y = r(rho) if ccode == `i'

corr hp_ln_y_ccode hp_ln_inv_ccode  if ccode == `i'
replace Corr_inv_y = r(rho) if ccode == `i'

corr hp_ln_y_ccode hp_CAy_ccode if ccode == `i'
replace Corr_CAy_y = r(rho) if ccode == `i'

corr hp_ln_y_ccode hp_tby_ccode if ccode == `i'
replace Corr_tby_y = r(rho) if ccode == `i'

corr hp_y_ccode hp_CA_ccode if ccode == `i'
replace Corr_CA_y = r(rho) if ccode == `i'

corr hp_ln_y_ccode hp_tb_ccode if ccode == `i'
replace Corr_tb_y = r(rho) if ccode == `i'

}
	

********************************************************
* Compute Serial Correlations
********************************************************


* Sort by the grouping variable
sort ccode

levelsof ccode, local(ccode)

local varlist hp_ln_y_ccode hp_ln_c_ccode hp_ln_m_ccode hp_ln_x_ccode hp_ln_g_ccode hp_ln_inv_ccode hp_CAy_ccode hp_tby_ccode hp_CA_ccode hp_tb_ccode

gen ACorr_y=.
gen ACorr_cons=.
gen ACorr_m=.
gen ACorr_x=.
gen ACorr_g=.
gen ACorr_tby=.
gen ACorr_CAy=.
gen ACorr_inv=.

sort ccode year

qui foreach i in `ccode' {

corr hp_ln_y_ccode L1.hp_ln_y_ccode if ccode == `i'
replace ACorr_y = r(rho) if ccode == `i'

corr hp_ln_c_ccode L1.hp_ln_c_ccode if ccode == `i'
replace ACorr_cons = r(rho) if ccode == `i'

corr hp_ln_m_ccode L1.hp_ln_m_ccode if ccode == `i'
replace ACorr_m = r(rho) if ccode == `i'

corr hp_ln_x_ccode L1.hp_ln_x_ccode if ccode == `i'
replace ACorr_x = r(rho) if ccode == `i'

corr hp_ln_g_ccode L1.hp_ln_g_ccode if ccode == `i'
replace ACorr_g = r(rho) if ccode == `i'

corr hp_tby_ccode L1.hp_tby_ccode if ccode == `i'
replace ACorr_tby = r(rho) if ccode == `i'

corr hp_CAy_ccode L1.hp_CAy_ccode if ccode == `i'
replace ACorr_CAy = r(rho) if ccode == `i'

corr hp_ln_inv_ccode L1.hp_ln_inv_ccode if ccode == `i'
replace ACorr_inv = r(rho) if ccode == `i'

}

********************************************************
* Compute Means
********************************************************

by ccode: egen mean_pop=mean(pop)
by ccode: egen mean_weight=mean(country_weight)
by ccode: egen mean_tby=mean(tby)
by ccode: egen mean_open=mean(open)
by ccode: egen mean_cy=mean(cy)
by ccode: egen mean_gy=mean(gy)
by ccode: egen mean_invy=mean(invy)
by ccode: egen mean_CAy=mean(CAy)

save std_correl.dta, replace


********************************************************
*compute statistics: weighted by population
********************************************************

*compute weighted statistics
local series_list sdy sdc_sdy sdg_sdy sdinv_sdy  sdx_sdy sdm_sdy sdtby sdCAy sdtbdy sdCAdy  tby open
local group_var Country_Name 

sort ccode

foreach var in `series_list' {
gen `var'_w = `var' * country_weight
gen `var'_w_D = `var' * country_weight_D
gen `var'_w_U = `var' * country_weight_U
gen `var'_w_EM = `var' * country_weight_EM

}


local var_list_corr Corr_y_y Corr_cons_y Corr_m_y Corr_x_y Corr_g_y Corr_tb_y Corr_tby_y Corr_CA_y Corr_CAy_y Corr_inv_y

foreach var in `var_list_corr' {
gen `var'_w = `var' * country_weight
gen `var'_w_D = `var' * country_weight_D
gen `var'_w_U = `var' * country_weight_U
gen `var'_w_EM = `var' * country_weight_EM
}


local var_list_corr ACorr_cons ACorr_m ACorr_x ACorr_g ACorr_tby ACorr_y ACorr_CAy ACorr_inv

foreach var in `var_list_corr' {
gen `var'_w = `var' * country_weight
gen `var'_w_D = `var' * country_weight_D
gen `var'_w_U = `var' * country_weight_U
gen `var'_w_EM = `var' * country_weight_EM
}

bysort ccode: keep if _n==1
drop cy y pop gy y_nom invy my xy tt CAy rer c x g m inv tby open tb ccode ln_m ln_c ln_x ln_inv
drop ln_y hp_ln_y_ccode hp_ln_c_ccode hp_ln_g_ccode hp_ln_m_ccode hp_ln_x_ccode hp_ln_inv_ccode hp_y_ccode trendy CAdy tbdy hp_CA_ccode hp_tb_ccode hp_CAy_ccode hp_tby_ccode
drop CA ln_g

save std_correl.dta,replace

************************
* generate LaTex tables
************************


*********************
* Standard Deviations
*********************

clear all
use std_correl.dta

*ST DEVS
eststo clear
label drop _all

* Clear previous stored results
eststo clear

* Temporarily remove existing labels for consistency
label drop _all

* Store Total results
eststo Total: total sdy_w sdc_sdy_w sdg_sdy_w sdinv_sdy_w sdx_sdy_w sdm_sdy_w sdtby_w sdCAy_w sdtbdy_w sdCAdy_w tby_w open_w

* Store D results
eststo D: total sdy_w_D sdc_sdy_w_D sdg_sdy_w_D sdinv_sdy_w_D sdx_sdy_w_D sdm_sdy_w_D sdtby_w_D sdCAy_w_D sdtbdy_w_D sdCAdy_w_D tby_w_D open_w_D

* Store EM results
eststo EM: total sdy_w_EM sdc_sdy_w_EM sdg_sdy_w_EM sdinv_sdy_w_EM sdx_sdy_w_EM sdm_sdy_w_EM sdtby_w_EM sdCAy_w_EM sdtbdy_w_EM sdCAdy_w_EM tby_w_EM open_w_EM

* Store U results
eststo U: total sdy_w_U sdc_sdy_w_U sdg_sdy_w_U sdinv_sdy_w_U sdx_sdy_w_U sdm_sdy_w_U sdtby_w_U sdCAy_w_U sdtbdy_w_U sdCAdy_w_U tby_w_U open_w_U

* Apply consistent labels across all variables
label variable sdy_w "Standard deviation of Y"
label variable sdy_w_D "Standard deviation of Y"
label variable sdy_w_EM "Standard deviation of Y"
label variable sdy_w_U "Standard deviation of Y"
label variable sdc_sdy_w "Consumption to Y"
label variable sdc_sdy_w_D "Consumption to Y"
label variable sdc_sdy_w_EM "Consumption to Y"
label variable sdc_sdy_w_U "Consumption to Y"
label variable sdg_sdy_w "Government to Y"
label variable sdg_sdy_w_D "Government to Y"
label variable sdg_sdy_w_EM "Government to Y"
label variable sdg_sdy_w_U "Government to Y"
label variable sdinv_sdy_w "Investment to Y"
label variable sdinv_sdy_w_D "Investment to Y"
label variable sdinv_sdy_w_EM "Investment to Y"
label variable sdinv_sdy_w_U "Investment to Y"
label variable sdx_sdy_w "Exports to Y"
label variable sdx_sdy_w_D "Exports to Y"
label variable sdx_sdy_w_EM "Exports to Y"
label variable sdx_sdy_w_U "Exports to Y"
label variable sdm_sdy_w "Imports to Y"
label variable sdm_sdy_w_D "Imports to Y"
label variable sdm_sdy_w_EM "Imports to Y"
label variable sdm_sdy_w_U "Imports to Y"
label variable sdtby_w "Trade Balance to Y"
label variable sdtby_w_D "Trade Balance to Y"
label variable sdtby_w_EM "Trade Balance to Y"
label variable sdtby_w_U "Trade Balance to Y"
label variable sdCAy_w "Current Account to Y"
label variable sdCAy_w_D "Current Account to Y"
label variable sdCAy_w_EM "Current Account to Y"
label variable sdCAy_w_U "Current Account to Y"
label variable sdtbdy_w "Trade Balance (Detail) to Y"
label variable sdtbdy_w_D "Trade Balance (Detail) to Y"
label variable sdtbdy_w_EM "Trade Balance (Detail) to Y"
label variable sdtbdy_w_U "Trade Balance (Detail) to Y"
label variable sdCAdy_w "Current Account (Detail) to Y"
label variable sdCAdy_w_D "Current Account (Detail) to Y"
label variable sdCAdy_w_EM "Current Account (Detail) to Y"
label variable sdCAdy_w_U "Current Account (Detail) to Y"
label variable tby_w "Trade Balance"
label variable tby_w_D "Trade Balance"
label variable tby_w_EM "Trade Balance"
label variable tby_w_U "Trade Balance"
label variable open_w "Openness"
label variable open_w_D "Openness"
label variable open_w_EM "Openness"
label variable open_w_U "Openness"

* Generate LaTeX table with all columns aligned
esttab Total D EM U using "TotalOnly.tex",  replace cells("b(fmt(2))")   noobs  nonumber nostar label title("Summary Table: Total, D, EM, and U Columns") 

*********************	
*CORRELATIONS
*********************

eststo clear
label drop _all

* Clear previous stored results
eststo clear

* Temporarily remove existing labels for consistency
label drop _all

* Store Total results
eststo TotalCorr: total Corr_y_y_w Corr_cons_y_w Corr_m_y_w Corr_x_y_w Corr_g_y_w Corr_tb_y_w Corr_tby_y_w Corr_CA_y_w Corr_CAy_y_w Corr_inv_y_w

*D
eststo DCorr: total Corr_y_y_w_D Corr_cons_y_w_D Corr_m_y_w_D Corr_x_y_w_D Corr_g_y_w_D Corr_tb_y_w_D Corr_tby_y_w_D Corr_CA_y_w_D Corr_CAy_y_w_D Corr_inv_y_w_D

*EM
eststo EMCorr: total Corr_y_y_w_EM Corr_cons_y_w_EM Corr_m_y_w_EM Corr_x_y_w_EM Corr_g_y_w_EM Corr_tb_y_w_EM Corr_tby_y_w_EM Corr_CA_y_w_EM Corr_CAy_y_w_EM Corr_inv_y_w_EM

*U
eststo UCorr: total Corr_y_y_w_U Corr_cons_y_w_U Corr_m_y_w_U Corr_x_y_w_U Corr_g_y_w_U Corr_tb_y_w_U Corr_tby_y_w_U Corr_CA_y_w_U Corr_CAy_y_w_U Corr_inv_y_w_U

* Generate LaTeX table with all columns aligned
esttab TotalCorr DCorr EMCorr UCorr using "TotalCorr.tex",  replace cells("b(fmt(2))")   noobs  nonumber nostar label title("Summary Table: Total, D, EM, and U Columns") 


*********************
* AutoCorrelations
*********************

eststo clear
label drop _all

* Clear previous stored results
eststo clear

* Temporarily remove existing labels for consistency
label drop _all

* Store Total results
eststo AutoCorr: total ACorr_y_w ACorr_cons_w ACorr_g_w  ACorr_inv_w ACorr_x_w  ACorr_m_w ACorr_tby_w  ACorr_CAy_w


*D
eststo DAutoCorr: total ACorr_y_w_D ACorr_cons_w_D ACorr_g_w_D  ACorr_inv_w_D ACorr_x_w_D  ACorr_m_w_D ACorr_tby_w_D  ACorr_CAy_w_D

*EM
eststo EMAutoCorr: total ACorr_y_w_EM ACorr_cons_w_EM ACorr_g_w_EM  ACorr_inv_w_EM ACorr_x_w_EM  ACorr_m_w_EM ACorr_tby_w_EM  ACorr_CAy_w_EM

*U
eststo UAutoCorr: total ACorr_y_w_U ACorr_cons_w_U ACorr_g_w_U  ACorr_inv_w_U ACorr_x_w_U  ACorr_m_w_U ACorr_tby_w_U  ACorr_CAy_w_U

* Generate LaTeX table with all columns aligned
esttab AutoCorr DAutoCorr EMAutoCorr UAutoCorr using "AutoCorr.tex",  replace cells("b(fmt(2))")   noobs  nonumber nostar label title("Summary Table: Total, D, EM, and U Columns") 
 
 
 drop y_p pop_c totpop totpop_D totpop_U totpop_EM 


drop sdy_w sdy_w_D sdy_w_U sdy_w_EM sdc_sdy_w sdc_sdy_w_D sdc_sdy_w_U sdc_sdy_w_EM sd g_sdy_w sdg_sdy_w_D sdg_sdy_w_U sdg_sdy_w_EM sdinv_sdy_w sdinv_sdy_w_D sdinv_sdy_w_U 
drop sdinv_sdy_w_EM sdx_sdy_w sdx_sdy_w_D sdx_sdy_w_U sdx_sdy_w_EM sdm_sdy_w sdm_sdy_w_D s
drop dm_sdy_w_U sdm_sdy_w_EM sdtby_w sdtby_w_D sdtby_w_U sdtby_w_EM sdCAy_w sdCAy_w_D sdCA
drop y_w_U sdCAy_w_EM sdtbdy_w sdtbdy_w_D sdtbdy_w_U sdtbdy_w_EM sdCAdy_w sdCAdy_w_D sdCAd
drop  y_w_U sdCAdy_w_EM tby_w tby_w_D tby_w_U tby_w_EM open_w open_w_D open_w_U open_w_EM C
drop orr_y_y_w Corr_y_y_w_D Corr_y_y_w_U Corr_y_y_w_EM Corr_cons_y_w Corr_cons_y_w_D Corr_
drop  cons_y_w_U Corr_cons_y_w_EM Corr_m_y_w Corr_m_y_w_D Corr_m_y_w_U Corr_m_y_w_EM Corr_x
drop  _y_w Corr_x_y_w_D Corr_x_y_w_U Corr_x_y_w_EM Corr_g_y_w Corr_g_y_w_D Corr_g_y_w_U Cor
drop r_g_y_w_EM Corr_tb_y_w Corr_tb_y_w_D Corr_tb_y_w_U Corr_tb_y_w_EM Corr_tby_y_w Corr_t
drop  by_y_w_D Corr_tby_y_w_U Corr_tby_y_w_EM Corr_CA_y_w Corr_CA_y_w_D Corr_CA_y_w_U Corr_
drop  CA_y_w_EM Corr_CAy_y_w Corr_CAy_y_w_D Corr_CAy_y_w_U Corr_CAy_y_w_EM Corr_inv_y_w Cor
drop  r_inv_y_w_D Corr_inv_y_w_U Corr_inv_y_w_EM ACorr_cons_w ACorr_cons_w_D ACorr_cons_w_U
drop   ACorr_cons_w_EM ACorr_m_w ACorr_m_w_D ACorr_m_w_U ACorr_m_w_EM ACorr_x_w ACorr_x_w_D
drop   ACorr_x_w_U ACorr_x_w_EM ACorr_g_w ACorr_g_w_D ACorr_g_w_U ACorr_g_w_EM ACorr_tby_w 
drop  ACorr_tby_w_D ACorr_tby_w_U ACorr_tby_w_EM ACorr_y_w ACorr_y_w_D ACorr_y_w_U ACorr_y_
drop  w_EM ACorr_CAy_w ACorr_CAy_w_D ACorr_CAy_w_U ACorr_CAy_w_EM ACorr_inv_w ACorr_inv_w_D
drop   ACorr_inv_w_U ACorr_inv_w_EM 

save std_correl.dta, replace


clear all
use std_correl.dta

drop Country_Code 
drop country_weight country_weight_D country_weight_U country_weight_EM 

