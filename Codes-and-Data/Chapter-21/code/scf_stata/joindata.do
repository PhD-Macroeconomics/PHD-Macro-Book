clear all
set mem 4000m
set maxvar 10000 
set more off
set trace off

global datadir = "D:/SCF/"

/* CPI-U-RS 
   www.bls.gov/cpi/cpiurs1978_2009.pdf 
   www.bls.gov/cpi/cpiursai1978_2011.pdf
   www.bls.gov/cpi/cpirsai1978-2013.pdf
   www.bls.gov/cpi/research-series/allitems.pdf 
   current base year 2007 (September) */
//global basecpi = 3062 
//global baseyear = 2007
/* Benchmark is that all Dollar values are reported in real 2007 Dollars. 
   If this should be changed to a different year, then the base year has 
   to be adapted.*/

//global baseyear = 2004
//global basecpi = 2788 

//global basecpi = 3208 
//global baseyear = 2010

//global basecpi = 3438 
//global baseyear = 2013

//global basecpi = 3781
//global baseyear = 2019

global basecpi = 4376
global baseyear = 2022


/* NOTE: CPIs did change in the last version of the BLS series (see link in line 13) */
forvalues y = 1989(3)2022 {
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
	
	
	do "${datadir}`y'/makeupdata.do"
	gen year = `y'
	do "${datadir}scflabel.do"
	save "${datadir}`y'/scf`y'wealth_cpi${baseyear}", replace
	if(${baseyear} == 2007) {
		save "${datadir}`y'/scf`y'wealth", replace
		}
	clear
	}

use "${datadir}1989/scf1989wealth_cpi${baseyear}.dta", clear
label data "Wealth and Income information from the Survey of Consumer Finances (${baseyear} dollars)"

forvalues y = 1992(3)2022 {
	append using "${datadir}`y'/scf`y'wealth_cpi${baseyear}.dta"
	}
	
save "${datadir}scfwealth_cpi${baseyear}", replace

if(${baseyear} == 2007) {
	save "${datadir}scfwealth.dta", replace
	}

clear


