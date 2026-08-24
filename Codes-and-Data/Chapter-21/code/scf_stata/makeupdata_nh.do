*** do-file for wealth categories ***

/**************************************************************************** 
*** STATA code adapted from SAS code for the SCF survey bulletin articles ***
***									                                      ***
*** Moritz Kuhn, University of Bonn, 2024			                      ***
****************************************************************************/


/* Variable lists */
local children "X108 X114 X120 X126 X132 X202 X208 X214 X220 X226" 
local agemembers "X8022 X104 X110 X116 X122 X128 X134 X204 X210 X216 X222 X228"


local wthdrlst1 = "X6464 X6469 X6474 X6479 X6484 X6489 X6965 X6971 X6977 X6983 X6989 X6995"
local wthdrlst2 = "X6465 X6470 X6475 X6480 X6485 X6490 X6966 X6972 X6978 X6984 X6990 X6996"

/* Different for surveys before 2004 */
local ptype1 "X11000 X11100 X11300 X11400"
local ptype2 "X11001 X11101 X11301 X11401"
local pamt   "X11032 X11132 X11332 X11432"
local pbor   "X11025 X11125 X11325 X11425"
local pwit   "X11031 X11131 X11331 X11431"
local pall   "X11036 X11136 X11336 X11436"
local ppct   "X11037 X11137 X11337 X11437"
local ptype3 "X11070 X11170 X11370 X11470"


use "${datadir}2022/scf2022.dta", clear


/* Generate indicator variables */
gen indi1 = .
gen indi2 = .
gen indi3 = .

********************
* generate weights
********************
gen id = Y1			/* Every observation of a implicate gets a distinct id */
gen impl = Y1 - YY1*10		/* Id for the implicate */
gen pers = YY1			/* Observations in differnt implicates have the same id */
gen double wgt = X42001 	/* Use this weight if only one implicate is considered */
gen double wgt1 = X42001/5	/* Use this weight if all implicates are considered at the same time, there are 5 implicates in total */


**********************
* Data adjustments 
**********************
/* Consider all finance companies reported in mortgage grids to be mortgage companies */
local numvars : word count `financial_instit' /* Number of variables in string */
local i = 1
while `i' <= `numvars' {
	local var1 : word `i' of `financial_instit'
	quietly : replace `var1' = 18 if `var1' == 14 
	local i = `i' + 1
	}

**************************************************************
* demographic characteristics
**************************************************************

/* Age of the household head */
gen age = X14

/* Sex of household head */
gen sex = X8021

/* Define age categories 
1 : < 35
2 : 35 - 44
3 : 45 - 54
4 : 55 - 64
5 : 65 - 74
6 : >= 75     */
gen agecl = 1 + (age >= 35) + (age >= 45) + (age >= 55) + (age >= 65) + (age >= 75)

/* Education of the household head */
gen educ = X5931

/* Education of spouse */
gen educ_spouse = X6111
 
/* Define education categories of the household head 
1 : no high school diploma/GED
2 : high school diploma/GED
3 : some college
4 : college degree
*/
gen educl = 1
quietly : replace educl = 2 if (X5932 == 1 | X5932 == 2)
quietly : replace educl = 2 if educ == 8
quietly : replace educl = 3 if inlist(educ,9,10,11)
quietly : replace educl = 4 if inrange(educ,12,15)

/* Define education categories of spouse
same as for the household head
*/
gen educl_spouse = 1
quietly: replace educl_spouse = 2 if (X6112 == 1 | X6112 == 2)
quietly : replace educl = 2 if educ_spouse == 8
quietly : replace educl = 3 if inlist(educ_spouse,9,10,11)
quietly : replace educl = 4 if inrange(educ_spouse,12,15)

/* Race of Household head 
 1 = white non-Hispanic
 2 = black/African-American
 3 = Hispanic,
 4 = other */
 
 /* Special adjustment for 2022 forward, need to undo the swapping of
    the race/ethnicity questions so that the constructed race variables
    use the race of the interview respondent, as in years prior to 2022,
    only keep first two race questions responses in pubic data  */
replace X6809 = X8049 if X8000 == 1  
 
gen race = 4
quietly : replace race = 1 if X6809 == 1 
quietly : replace race = 2 if X6809 == 2 
quietly : replace race = 3 if X6809 == 3 


/* Marital status of household head 
1 : married or living with partner
2 : neither married nor living with partner */
gen married = 2
quietly : replace married = 1 if (X8023 == 1 | X8023 == 2)

/* Number of children 
including natural children, step-children, and foster children of head/spouse/partner */
/* NOTE: From 1995 forward, household listing information collected for one fewer household member */
gen kids = 0
foreach var of varlist `children' {
	quietly : replace kids = kids + 1 if (`var' == 4 | `var' == 13 | `var' == 36)
	}

/* Age of household members: First member is head, second member is spouse. 
   For the respondent, this variable contains the date of birth age. This age 
   might differ from age in X14 above in some cases. */
local i = 1	
foreach var of varlist `agemembers' {
	gen agemember`i' = `var'
	local i = `i' + 1
	} 	
	
/* Size of the household according to OECD equivalence scale 
Head : weight = 1
additional adult : weight = 0.7
kids : weight = 0.5 */
gen householdsize = 1 
forvalues i = 2(1)12 {
	quietly : replace householdsize = householdsize + (agemember`i' > 0) * 0.5 + (agemember`i' >= 18) * 0.2
	}

/* Labor force participation 
0 : not working at all
1 : working in some way */
gen lfpart = 1
quietly : replace lfpart = 0 if ((X4100 >= 50 & X4100 <= 80) | X4100 == 97)

/* Life-cycle status 
1 : head under 55, not married or living with partner, no children
2 : head under 55, married or living with partner, no children
3 : head under 55, married or living with partner, children
4 : head under 55, not married or living with partner, children
5 : head 55 or older and working
6 : head 55 or older and not working
*/
gen lifecycle = .
quietly : replace lifecycle = 1 if (age < 55 & married != 1 & kids == 0)
quietly : replace lifecycle = 2 if (age < 55 & married == 1 & kids == 0)
quietly : replace lifecycle = 3 if (age < 55 & married == 1 & kids > 0)
quietly : replace lifecycle = 4 if (age < 55 & married != 1 & kids > 0)
quietly : replace lifecycle = 5 if (age >= 55 & lfpart == 1)
quietly : replace lifecycle = 6 if (age >= 55 & lfpart == 0)


/* Occupation categories 
1 : work for someone else
2 : self-employed / partnership
3 : retired / disabled, student / homemaker / misc. not working, and age 65 or older
4 : other groups not working, mainly those under 65 and out of the labor force
*/
gen occat = .
quietly : replace occat = 1 if (X4106 == 1)
quietly : replace occat = 2 if ((X4106 == 2 | X4106 == 3 | X4106 == 4) & occat >= .)
quietly : replace occat = 3 if ((X4100 == 50 | X4100 == 52) & occat >= .)
quietly : replace occat = 3 if ((X4100 == 21 | X4100 == 23 | X4100 == 30 | X4100 == 70 | X4100 == 80 | X4100 == 97 | X4100 == 85 | X4100 == -7) & age >= 65 & occat >= .)
quietly : replace occat = 4 if (age < 65 & occat >= .)
label variable occat "occupation coding change in 2022 survey"


/* Sector variables 
1 : Agriculture, Forestry, Fishing and Hunting
2 : Mining
3 : Manufactoring
4 : Wholesale Trade, Retail Trade, and Restaurants
5 : Rental and Leasing, Software and Data Processing, and Repair and Maintenance
6 : Telecommunication, Utilities, Finance, Real Estate, Insurance, Scientific, 
    Education, Administration, Arts, Entertainment, Hospital, Personal, and Laundry Services  
7 : Public Administration and Armed Forces
*/
gen industry = X7402
label variable industry "industry coding change in 2022 survey"

**************************************************************************
* Health status 
**************************************************************************
gen healthhead = X6030
gen healthspouse = X6124

**************************************************************************
* Income 
**************************************************************************

/* Household income in the previous calender year */
gen income = max(0,X5729)

/* For 2004 and beyond, add in the amount of withdrawals from IRAs and tax-deferred pension 
   accounts (already included in earlier years). Need to convert pension withdrawals to annual 
   frequency. In 2010, the 5th and 6th current and future pension grids are droppped. */
/* Convert to monthly frequency */
local amountlist "X6464 X6469 X6474 X6479 X6965 X6971 X6977 X6983"
local freqlist "X6465 X6470 X6475 X6480 X6966 X6972 X6978 X6984"
local numvars : word count `amountlist' 
local i = 1
while `i' <= `numvars' {
	local avar : word `i' of `amountlist'
	local fvar : word `i' of `freqlist'
	quietly : replace `avar' = `avar' * 12 * (`fvar' == 4) + `avar' * 4 * (`fvar' == 5) + `avar' * (`fvar' == 6) + `avar' * (`fvar' <= 0)
	local i = `i' + 1
	}
gen pensionwithdrawal = X6558 + X6566 + X6574 + max(0,X6464) + max(0,X6469) + max(0,X6474) + max(0,X6479) /*
                   */  + max(0,X6965) + max(0,X6971) + max(0,X6977) + max(0,X6983)

/* Income excluding pension withdrawal */
gen incomenowithdraw = income				   
label variable incomenowithdraw "Household income in the previous calender year (excl. pension withdraw)"
/* Add in pension withdrawal to income */
replace income = income + pensionwithdrawal			   
label variable income "Household income in the previous calender year (incl. pension withdraw)"
/* Permanent / normal income */
gen norminc = income
quietly: replace norminc = max(0,X7362) + pensionwithdrawal	if X7650 != 3
label variable norminc "Household's self reported normal income"


/*  Income categories 
X5702 :	wages and salaries
X5704 :	professional practice, business or farm
X5706 :	non-taxable investments such as municipal bonds
X5708 :	interest income
X5710 :	dividends
X5712 :	net gains or losses from the sale of stocks, bonds, or real estate
X5714 :	net rent, trust income, or royalties from any other investment or business
X5716 :	unemployment or worker's compensation
X5718 :	child support or alimony
X5720 :	ADC AFDC, food stamps, or other forms of welfare or assistance, such as SSI
X5722 :	income from Social Security or other pensions, annuities, or other disability or retirement programs
*/

/* Labor income */
gen laborincome = X5702
label variable laborincome "Wages and salaries"

gen busifarmincome = X5704 + X5714
label variable busifarmincome "Business or farm income"

gen intdivincome = X5706 + X5708 + X5710
label variable intdivincome "Interest and dividend income"

gen capitalgains = X5712
label variable capitalgains "Net capital gains or losses"

gen socialsecurity = X5722 	
label variable socialsecurity "Income from Social Security"

gen unemployment = X5716
label variable unemployment "Unemployment or worker's compensation"

/* NOTE: In contrast to earlier years of the SCF, the 2004 SCF does not include withdrawals from IRA's and other 
         tax deferred pension accounts in "other" income. To create a measure comparable to that in the earlier 
           surveys, users should add in the amount of withdrawals from IRAs and tax-deferred pension accounts to X5724 */
gen otherincome = X5718 + X5720 + X5724 + pensionwithdrawal
label variable otherincome "Other sources of income"


local incomeclasses "income norminc incomenowithdraw laborincome busifarmincome intdivincome capitalgains socialsecurity unemployment otherincome"

/* CPI adjustment for income */
local numvars : word count `incomeclasses' 
local i = 1
while `i' <= `numvars' {
	local kvar : word `i' of `incomeclasses'
	quietly : replace `kvar' = `kvar' * $cpilag
	local i = `i' + 1
	}

/********************************************************************************
   LABOR MARKET DATA
********************************************************************************/	
/* Doing work for pay */
gen paidwork = X4105
/* Unemployment */
gen unemployed = X6780
gen unemplduration = X6781

/* Labor income household head */
/* Hours worked of household head (all jobs) */
gen headhoursworked = max(X4110,0)
gen headweeksworked = X4111	
gen headhoursworked2nd = max(X4507,0) + 95 * (X4507 == -2)
/* Truncate hours per week at 95 hours */
replace headhoursworked2nd = 95 - headhoursworked if headhoursworked + headhoursworked2nd > 95
gen headweeksworked2nd = X4508			
gen headannualhours = headweeksworked * headhoursworked 
gen headannualhours2nd = headweeksworked2nd * headhoursworked2nd
gen headincome = max(X4112,0) * $cpilag		
gen headincome2nd = max(X4509,0) * $cpilag			
quietly {
	/* Main job */
	 replace headincome = headincome * (365 * (X4113 == 1) + 365/7 * (X4113 == 2) + 365/14 * (X4113 == 3) + 12 * (X4113 == 4) /*
	*/ + 4 * (X4113 == 5) + 1 * (X4113 == 6) + 1 * (X4113 == 8) + 2 * (X4113 == 11) + 6 * (X4113 == 12) + 24 * (X4113 == 31))
	 replace headincome = headincome * headannualhours if X4113 == 18
	 replace headincome = . if X4113 == 14 | X4113 == -7 | X4113 == 22	
	/* Second job */
	 replace headincome2nd = headincome2nd * (365 * (X4510 == 1) + 365/7 * (X4510 == 2) + 365/14 * (X4510 == 3) + 12 * (X4510 == 4) /*
	*/ + 4 * (X4510 == 5) + 1 * (X4510 == 6) + 1 * (X4510 == 8) + 2 * (X4510 == 11) + 6 * (X4510 == 12) + 24 * (X4510 == 31))
	 replace headincome2nd = headincome2nd * headannualhours2nd if X4510 == 18
	 replace headincome2nd = . if X4510 == 14 | X4510 == -7 | X4510 == 22
	}
/* Store only total head income */
replace headincome = headincome + headincome2nd
replace headannualhours = headannualhours + headannualhours2nd
	
/* Labor income spouse */	
gen spousehoursworked = max(X4710,0)
gen spouseweeksworked = X4711	
gen spousehoursworked2nd = max(X5107,0) + 95 * (X5107 == -2)
/* Truncate hours per week at 95 hours */
replace spousehoursworked2nd = 95 - spousehoursworked if spousehoursworked + spousehoursworked2nd > 95		
gen spouseweeksworked2nd = X5108		
gen spouseannualhours = spouseweeksworked * spousehoursworked
gen spouseannualhours2nd = spouseweeksworked2nd * spousehoursworked2nd
gen spouseincome = max(X4712,0) * $cpilag	
gen spouseincome2nd = max(X5109,0) * $cpilag			
quietly {
	/* Main job */
	 replace spouseincome = spouseincome * (365 * (X4713 == 1) + 365/7 * (X4713 == 2) + 365/14 * (X4713 == 3) + 12 * (X4713 == 4) /*
	*/ + 4 * (X4713 == 5) + 1 * (X4713 == 6) + 1 * (X4713 == 8) + 2 * (X4713 == 11) + 6 * (X4713 == 12) + 24 * (X4713 == 31))
	 replace spouseincome = spouseincome * spouseannualhours if X4713 == 18
	 replace spouseincome = . if X4713 == 14 | X4713 == -7 | X4713 == 22
	 /* Second job */
	 replace spouseincome2nd = spouseincome2nd * (365 * (X5110 == 1) + 365/7 * (X5110 == 2) + 365/14 * (X5110 == 3) + 12 * (X5110 == 4) /*
	*/ + 4 * (X5110 == 5) + 1 * (X5110 == 6) + 1 * (X5110 == 8) + 2 * (X5110 == 11) + 6 * (X5110 == 12) + 24 * (X5110 == 31))
	 replace spouseincome2nd = spouseincome2nd * spouseannualhours2nd if X5110 == 18
	 replace spouseincome2nd = . if X5110 == 14 | X5110 == -7 | X5110 == 22
	}
/* Store only total spouse income */
replace spouseincome = spouseincome + spouseincome2nd
replace spouseannualhours = spouseannualhours + spouseannualhours2nd

/* Labor market history and employment status variables */	
gen expectedtenure = X4116

/* Employment status */
gen employmentstatushead = X4100
gen employmentstatusspouse = X4700

/* Size of employer */
gen employersizehead = X4114
gen employersizespouse = X4714

/* Employer tenure */
gen employertenurehead = X4115
gen employertenurespouse = X4715
	
**************************************************************************
* Assets, debts, networth, and related variables
**************************************************************************

**********************************************************
* Generate Data Categories
**********************************************************
* - financial assets
* - housing wealth
* - vehicles
* - Business
* - education loans
* - other consumer loans

******************* 
* financial assets  
*******************

/* checking accounts other than money market accounts */
gen checking = max(0,X3506) * (X3507 == 5) /*
	  */ + max(0,X3510) * (X3511 == 5) /*
	  */ + max(0,X3514) * (X3515 == 5) /*
	  */ + max(0,X3518) * (X3519 == 5) /*
	  */ + max(0,X3522) * (X3523 == 5) /*
	  */ + max(0,X3526) * (X3527 == 5) /*
	  */ + max(0,X3529) * (X3527 == 5)
		
		
/* prepaid cards */
gen prepaid = max(0,X7596)
	  
/* savings accounts */
/* different variables for the 2001 survey and before */
gen saving = max(0,X3730 * (X3732 != 4 & X3732 != 30)) /*
	*/ + max(0,X3736 * (X3738 != 4 & X3738 != 30)) /*
	*/ + max(0,X3742 * (X3744 != 4 & X3744 != 30)) /*
	*/ + max(0,X3748 * (X3750 != 4 & X3750 != 30)) /*
	*/ + max(0,X3754 * (X3756 != 4 & X3756 != 30)) /*
	*/ + max(0,X3760 * (X3762 != 4 & X3762 != 30)) /*
	*/ + max(0,X3765)
	 

/* money market deposit accounts */
/* NOTE : includes money market accounts used for checking and 
	  other money market account held at commerical banks, 
	  savings and loans, savings banks, and credit unions */
/* different variables for the 2001 survey and before */
gen moneymarket_deposit = max(0,X3506) * ((X3507==1) * (11 <= X9113 & X9113 <= 13)) /*
	*/ + max(0,X3510) * ((X3511==1) * (11 <= X9114 & X9114 <= 13)) /*
	*/ + max(0,X3514) * ((X3515==1) * (11 <= X9115 & X9115 <= 13)) /*
	*/ + max(0,X3518) * ((X3519==1) * (11 <= X9116 & X9116 <= 13)) /*
	*/ + max(0,X3522) * ((X3523==1) * (11 <= X9117 & X9117 <= 13)) /*	
	*/ + max(0,X3526) * ((X3527==1) * (11 <= X9118 & X9118 <= 13)) /*
	*/ + max(0,X3529) * ((X3527==1) * (11 <= X9118 & X9118 <= 13)) /*
	*/ + max(0,X3730 * (X3732==4 | X3732==30) * (11 <= X9259 & X9259 <= 13)) /*
	*/ + max(0,X3736 * (X3738==4 | X3738==30) * (11 <= X9260 & X9260 <= 13)) /*
	*/ + max(0,X3742 * (X3744==4 | X3744==30) * (11 <= X9261 & X9261 <= 13)) /*
	*/ + max(0,X3748 * (X3750==4 | X3750==30) * (11 <= X9262 & X9262 <= 13)) /*
	*/ + max(0,X3754 * (X3756==4 | X3756==30) * (11 <= X9263 & X9263 <= 13)) /*
	*/ + max(0,X3760 * (X3762==4 | X3762==30) * (11 <= X9264 & X9264 <= 13)) /*
	*/ + max(0,X3765 * (X3762==4 | X3762==30) * (11 <= X9264 & X9264 <= 13)) 
	

/* money market mutual funds */
/* NOTE : includes money market accounts used for checking and 
	  other money market account held at institutions other 
	  than commerical banks, savings and loans, savings banks, 
	  and credit unions */	
/* different variables for the 2001 survey and before */
gen moneymarket_mutualfunds = max(0,X3506) * ((X3507==1) * (X9113 < 11 | 13 < X9113)) /*
	*/ + max(0,X3510) * ((X3511==1) * (X9114 < 11 | 13 < X9114)) /*
	*/ + max(0,X3514) * ((X3515==1) * (X9115 < 11 | 13 < X9115)) /*
	*/ + max(0,X3518) * ((X3519==1) * (X9116 < 11 | 13 < X9116)) /*
	*/ + max(0,X3522) * ((X3523==1) * (X9117 < 11 | 13 < X9117)) /*	
	*/ + max(0,X3526) * ((X3527==1) * (X9118 < 11 | 13 < X9118)) /*
	*/ + max(0,X3529) * ((X3527==1) * (X9118 < 11 | 13 < X9118)) /*
	*/ + max(0,X3730 * (X3732==4 | X3732==30) * (X9259 < 11 | 13 < X9259)) /*
	*/ + max(0,X3736 * (X3738==4 | X3738==30) * (X9260 < 11 | 13 < X9260)) /*
	*/ + max(0,X3742 * (X3744==4 | X3744==30) * (X9261 < 11 | 13 < X9261)) /*
	*/ + max(0,X3748 * (X3750==4 | X3750==30) * (X9262 < 11 | 13 < X9262)) /*
	*/ + max(0,X3754 * (X3756==4 | X3756==30) * (X9263 < 11 | 13 < X9263)) /*
	*/ + max(0,X3760 * (X3762==4 | X3762==30) * (X9264 < 11 | 13 < X9264)) /*
	*/ + max(0,X3765 * (X3762==4 | X3762==30) * (X9264 < 11 | 13 < X9264))  
	
	
/* All types of money market accounts */
gen moneymarket = moneymarket_deposit + moneymarket_mutualfunds

/* Call accounts at brokerages */
gen callaccount = max(0,X3930)

/* Liquid assets : all types of transactions accounts */
gen liquidassets = checking + saving + moneymarket + callaccount + prepaid

/* Certificates of deposit */
gen certdeposit = max(0,X3721)

/* mutual funds */ 
/* stock mutual funds */
gen stmf = max(0,X3822) * (X3821 == 1)

/* tax free bond mutual funds */
gen tfbmf = max(0,X3824) * (X3823 == 1)

/* government bond mutual funds */
gen gbmf = max(0,X3826) * (X3825 == 1)

/* other bond mutual funds */
gen obmf = max(0,X3828) * (X3827 == 1)

/* combination and other mutual funds */
gen comf = max(0,X3830) * (X3829 == 1)

/* other mutual funds */
/* Starting in 2004 */
gen omf = max(0,X7787) * (X7785 == 1)

/* total directly held mutual funds, excluding money market mutual funds */
/* Starting in 2004 add other mutual funds (omf) */
gen mutualfunds = stmf + tfbmf + gbmf + obmf + comf + omf


/* stocks */
gen stocks = max(0,X3915)

/* bonds : not including bond funds or savings bonds */
/* tax-exempt bonds (state and local bonds) */
gen nontaxbonds = X3910

/* mortage-backed bonds */
gen mortagebonds = X3906

/* US government and government agency bonds and bills */
gen govtbonds = X3908

/* Corporate and foreign bonds */
/* Other variables before 1992 */
gen otherbonds = X7633 + X7634 

/* Total bonds : not including bond funds or saving bonds */
gen bonds = nontaxbonds + mortagebonds + govtbonds + otherbonds


/* Retirement accounts */
/* quasi-liquid retirement accounts (IRAs and thrift-type accounts)
   individual retirement accounts / Keoghs */
   
/* Adjustment necessary for surveys before 2004 */

gen irakeogh = X6551 + X6559 + X6567 + X6552 + X6560 + X6568 + X6553 + X6561 + X6569 + X6554 + X6562 + X6570
replace irakeogh = 0 if irakeogh >= .

/* Account-type pension plans (included if type is 401k, 403b, thrift, savings, SRA, 
   or if participant has option to borrow or withdraw). */

/* Thrift amounts invested in stocks */
gen pensionequity = 0
gen holdings = 0

gen req = 0
gen seq = 0
gen thrift  = 0
gen rthrift = 0
gen sthrift = 0

local numvars : word count `ptype1' /* Number of variables in string ptype1 */
local i = 1
while `i' <= `numvars' {
	local p1var   : word `i' of `ptype1'
	local p2var   : word `i' of `ptype2'
	local pamtvar : word `i' of `pamt'
	local pborvar : word `i' of `pbor'
	local pwitvar : word `i' of `pwit'
	local pallvar : word `i' of `pall'
	local ppctvar : word `i' of `ppct'
	
	quietly : replace indi1 = (`p1var' == 1 | `p2var' == 2 | `p2var' == 3 | `p2var' == 4 | `p2var' == 6 | `p2var' == 20 | `p2var' == 21 | `p2var' == 22 | `p2var' == 26 | `pborvar' == 1 | `pwitvar' == 1)
	
	quietly : replace holdings = max(0,`pamtvar') * indi1
	if (`i' <= 2){
		quietly : replace rthrift = rthrift + holdings
		}
	else{
		quietly : replace sthrift = sthrift + holdings
		}
	
	quietly : replace thrift = thrift + holdings
	quietly : replace pensionequity = pensionequity + holdings * (((`pallvar' == 1) + (`pallvar' == 3 | `pallvar' == 30)) * (max(0,`ppctvar')/10000))
	
	if(`i' <= 2){
		quietly : replace req = pensionequity
		}
	else{
		quietly : replace seq = pensionequity - req
		}
		
	local i = `i' + 1
	}

/* Allocate the pension mopups */
/* where possible, use information for first three pensions to infer characteristics of this amount, 
   where not possible to infer whether R can borrow / make withdrawals, assume this is possible, 
   where not possible to determine investment direction, assume half in stocks */

quietly: replace holdings = .
gen pmop = .

local p1var1   : word 1 of `ptype1'
local p1var2   : word 2 of `ptype1'
local p1var3   : word 3 of `ptype1'
local p1var4   : word 4 of `ptype1'

local p2var1   : word 1 of `ptype2'
local p2var2   : word 2 of `ptype2'
local p2var3   : word 3 of `ptype2'
local p2var4   : word 4 of `ptype2'

local pborvar1 : word 1 of `pbor'
local pborvar2 : word 2 of `pbor'
local pborvar3 : word 3 of `pbor'
local pborvar4 : word 4 of `pbor'

local pwitvar1 : word 1 of `pwit'
local pwitvar2 : word 2 of `pwit'
local pwitvar3 : word 3 of `pwit'
local pwitvar4 : word 4 of `pwit'

quietly : replace indi1 = (`p1var1' == 1 | `p1var2' == 1 | `p2var1' == 2 | `p2var1' == 3 |`p2var1' == 4 | `p2var1' == 6 | `p2var1' == 20 | `p2var1' == 21 | `p2var1' == 22 | `p2var1' == 26 | `p2var2' == 2 | `p2var2' == 3 |`p2var2' == 4 | `p2var2' == 6 | `p2var2' == 20 | `p2var2' == 21 | `p2var2' == 22 | `p2var2' == 26 | `pwitvar1' == 1 | `pwitvar2' == 1 | `pborvar1' == 1 | `pborvar2' == 1)
quietly : replace indi2 = (`p1var1' != 0 & `p1var2' != 0 & `pwitvar1' != 0 & `pwitvar2' != 0)

quietly : replace pmop = X11259 if ( indi1 == 1 & X11259 > 0)
quietly : replace pmop = 0 if ( indi2 == 1 & X11259 >0)
quietly : replace pmop = X11259 if (indi1 != 1 & indi2 != 1 & X11259 > 0)
quietly : replace thrift = thrift + pmop  if (indi1 != 1 & indi2 != 1 & X11259 > 0)
quietly : replace pensionequity = pensionequity + pmop * (req/rthrift) if (req > 0 & X11259 > 0)
quietly : replace pensionequity = pensionequity + 0.5 * pmop if (req <= 0 & X11259 > 0)


quietly : replace indi1 = (`p1var3' == 1 | `p1var4' == 1 | `p2var3' == 2 | `p2var3' == 3 | `p2var3' == 4 | `p2var3' == 6 | `p2var3' == 20 | `p2var3' == 21 | `p2var3' == 22 | `p2var3' == 26 | `p2var4' == 2 | `p2var4' == 3 |`p2var4' == 4 | `p2var4' == 6 | `p2var4' == 20 | `p2var4' == 21 | `p2var4' ==22 | `p2var4' ==26 | `pwitvar3' == 1 | `pwitvar4' == 1 | `pborvar3' == 1 | `pborvar4' == 1)
quietly : replace indi2 = (`p1var3' != 0 & `p1var4' != 0 & `pwitvar3' != 0 & `pwitvar4' != 0)
	
quietly : replace pmop = X11559 if (indi1 == 1 & X11559 > 0)
quietly : replace pmop = 0 if (indi2 == 1 & X11559 > 0)
quietly : replace pmop = X11559 if (indi1 != 1 & indi2 != 1 & X11559 > 0)
quietly : replace thrift = thrift + pmop if (indi1 != 1 & indi2 != 1 & X11559 > 0)
quietly : replace pensionequity = pensionequity + pmop * (seq/sthrift) if (seq > 0 & X11559 > 0)
quietly : replace pensionequity = pensionequity + 0.5 * pmop if (seq <= 0 & X11559 > 0)
	

/* Drop temporary variables */
drop holdings pmop rthrift sthrift req seq

/* Future pensions (accumulated in an account for the R/S) */
gen futurepension = max(0,X5604) + max(0,X5612) + max(0,X5620) + max(0,X5628)

/* NOTE : there is very little evidence that pensions with currently received benefits recorded in the SCFs 
	  before 2001 were any type of 401k or related account from which the R was making withdrawals : 
	  the question added in 2001 allow one to distinguish such account, and there are 55 of them in that 
	  year : create a second version of "retqliq" to include this information. */ 

/* Adjust for surveys before 2004 */
gen currentpension = X6462 + X6467 + X6472 + X6477 + X6957
/* total quasi-liquid : sum of IRAs, thrift accounts, and future pensions. This version includes currently received benefits */
gen retireliquidassets = irakeogh + thrift + futurepension + currentpension

/* saving bonds */
gen savingbonds = X3902

/* cash value of life-insurance */
gen cashlifeinsurance = max(0,X4006)

/* Other managed assets : trusts, annuities and managed 
	investment accounts in which the household has 
	equity interest */
/* Different variables for years before 2004 */
gen annuities = max(0,X6577)
gen trusts = max(0,X6587)
gen othermgdinvest = annuities + trusts

/* Other financial assets : includes loans from the household to someone else,
	future proceeds, royalties, futures, non-public stock, deferred compensation
	oil / gas / mineral investment, cash n.e.c. (?) */
quietly : replace indi1 = (X4020 == 61 | X4020 == 62 | X4020 == 63 | X4020 == 64 | X4020 == 65 | X4020 == 66 ) /*
	*/ + (X4020 == 71 | X4020 == 72 | X4020 == 73 | X4020 == 74 | X4020 == 77 ) /*
	*/ + (X4020 == 80 | X4020 == 81 | X4020 == -7 )
quietly : replace indi2 = (X4024 == 61 | X4024 == 62 | X4024 == 63 | X4024 == 64 | X4024 == 65 | X4024 == 66 ) /*
	*/ + (X4024 == 71 | X4024 == 72 | X4024 == 73 | X4024 == 74 | X4024 == 77 ) /*
	*/ + (X4024 == 80 | X4024 == 81 | X4024 == -7 )
quietly : replace indi3 = (X4028 == 61 | X4028 == 62 | X4028 == 63 | X4028 == 64 | X4028 == 65 | X4028 == 66 ) /*
	*/ + (X4028 == 71 | X4028 == 72 | X4028 == 73 | X4028 == 74 | X4028 == 77 ) /*
	*/ + (X4028 == 80 | X4028 == 81 | X4028 == -7 )
gen otherfinassets = X4018 + X4022 * indi1 + X4026 * indi2 + X4030 * indi3


/* Financial assets invested in stocks 
	
	1.) directly-held stock
	
	2.) stock mutual funds : full value if described as stock mutual fund, 50 % value of combination mutual funds 
	
	3.) IRAs/Keoghs invested in stocks
		(i)	full value if mostly invested in stocks
		(ii)  	50 % value if split between stocks and bonds or stocks and money market
		(iii)	33.3 % value if split between stock, bonds, and money market
		
	4.) other managed assets with equity interest (annuities, trusts, MIAs (?)) 
		(i)	full value if mostly invested in stocks
		(ii)  	50 % value if split between stocks and mutual funds or bonds and CDs, or "mixed/diversified"
		(iii)	33.3 % value if "other"
	
	5.) thrift-type retirement accounts invested in stock
		(i)  full value if mostly invested in stock
		(ii) 50 % value if split between stocks and interest earning assets 
	
	6.) saving accounts classified as 529 or other accounts that may be invested in stocks
	*/
/* Adjust for survey periods before 2004 */

/* Equity in directly hold stocks, stock mutual funds, and combination mutual funds */
gen directequity = stocks + stmf + 0.5 * comf

/* Equity in quasi liquid retirement assets */
/* Adjust for survey periods before 2007 */
gen retireequity = (X6551 + X6552 + X6553 + X6554) * ((X6555 == 1) + (X6555 == 3 | X6555 == 30) * (max(0,X6556)/10000)) /*
	      */ + (X6559 + X6560 + X6561 + X6562) * ((X6563 == 1) + (X6563 == 3 | X6563 == 30) * (max(0,X6564)/10000)) /*
	      */ + (X6567 + X6568 + X6569 + X6570) * ((X6571 == 1) + (X6571 == 3 | X6571 == 30) * (max(0,X6572)/10000)) /*
        	*/ + pensionequity /*
	      */ + X6462 * (X6461 == 1) * ((X6933 == 1) + (X6933 == 3 | X6933 == 30) * (max(0,X6934)/10000)) /*
	      */ + X6467 * (X6466 == 1) * ((X6937 == 1) + (X6937 == 3 | X6937 == 30) * (max(0,X6938)/10000)) /*
	      */ + X6472 * (X6471 == 1) * ((X6941 == 1) + (X6941 == 3 | X6941 == 30) * (max(0,X6942)/10000)) /*
	      */ + X6477 * (X6476 == 1) * ((X6945 == 1) + (X6945 == 3 | X6945 == 30) * (max(0,X6946)/10000)) /*
	      */ + X5604 * ((X6962 == 1) + (X6962 == 3 | X6962 == 30) * (max(0,X6963)/10000)) /*
	      */ + X5612 * ((X6968 == 1) + (X6968 == 3 | X6968 == 30) * (max(0,X6969)/10000)) /*
	      */ + X5620 * ((X6974 == 1) + (X6974 == 3 | X6974 == 30) * (max(0,X6975)/10000)) /*
	      */ + X5628 * ((X6980 == 1) + (X6980 == 3 | X6980 == 30) * (max(0,X6981)/10000)) /*
		*/ + X3730 * ((X7074 == 1)+(X7074 == 3 | X7074 == 30)*(max(0,X7075)/10000)) /*
        	*/ + X3736 * ((X7077 == 1)+(X7077 == 3 | X7077 == 30)*(max(0,X7078)/10000)) /*
        	*/ + X3742 * ((X7080 == 1)+(X7080 == 3 | X7080 == 30)*(max(0,X7081)/10000)) /*
        	*/ + X3748 * ((X7083 == 1)+(X7083 == 3 | X7083 == 30)*(max(0,X7084)/10000)) /*
        	*/ + X3754 * ((X7086 == 1)+(X7086 == 3 | X7086 == 30)*(max(0,X7087)/10000)) /*
        	*/ + X3760 * ((X7089 == 1)+(X7089 == 3 | X7089 == 30)*(max(0,X7090)/10000))

gen equity = directequity + retireequity + omf /*
	*/ + annuities * ((X6581 == 1) + (X6581 == 3) * X6582/10000) /*
	*/ + trusts * ((X6591 == 1) + (X6591 == 3) * X6592/10000) 
	
	
/* Ratio of equity to permanent / normal income */
gen equity2income = equity / max(100,norminc)

/* Total financial assets */
gen financialassets = liquidassets + certdeposit + mutualfunds + stocks + bonds + retireliquidassets + savingbonds + cashlifeinsurance + othermgdinvest + otherfinassets + prepaid


********************************************* 
* nonfinancial assets and related variables  
*********************************************

/* Value of all vehicles (includes autos, motor homes, RVs, airplanes, boats)*/
/* Adjust for surveys before 1995 */
gen vehicles = max(0,X8166) + max(0,X8167) + max(0,X8168) + max(0,X8188) + max(0,X2422) + max(0,X2506)+ max(0,X2606) + max(0,X2623)

/* value of owned vehicles */
/* Adjust for surveys before 1995 */
gen valueown = X8166 + X8167 + X8168 + X8188

/* leased vehicles */
gen valueleased = X8163 + X8164



*********************************************************************
* housing wealth
*********************************************************************

/* primary residence */
/* For farmers, assume x507 (percent of farm used for farming / ranching) is maxed at 90 % */
quietly : replace X507 = 9000 if (X507 > 9000)

/* Compute value of business part of farm net of outstanding mortgages */
gen farmbusiness = 0

quietly : replace farmbusiness = (X507/10000) * (X513 + X526 - X805 - X905 - X1005) if (X507 > 0)
quietly : replace X805  = X805 * ((10000 - X507)/10000)  if (X507 > 0)
quietly : replace X808  = X808 * ((10000 - X507)/10000)  if (X507 > 0)
quietly : replace X813  = X813 * ((10000 - X507)/10000)  if (X507 > 0)
quietly : replace X905  = X905 * ((10000 - X507)/10000)  if (X507 > 0)
quietly : replace X908  = X908 * ((10000 - X507)/10000)  if (X507 > 0)
quietly : replace X913  = X913 * ((10000 - X507)/10000)  if (X507 > 0)
quietly : replace X1005 = X1005 * ((10000 - X507)/10000) if (X507 > 0)
quietly : replace X1008 = X1008 * ((10000 - X507)/10000) if (X507 > 0)
quietly : replace X1013 = X1013 * ((10000 - X507)/10000) if (X507 > 0)
	
quietly : replace farmbusiness = farmbusiness - X1108 * (X507/10000) if (X1103 == 1 & X507 > 0)
quietly : replace X1108 = X1108 * ((10000 - X507)/10000) if(X1103 == 1 & X507 > 0)
quietly : replace X1109 = X1109 * ((10000 - X507)/10000) if(X1103 == 1 & X507 > 0)
		
quietly : replace farmbusiness = farmbusiness - X1119 * (X507/10000) if (X1114 == 1 & X507 > 0)
quietly : replace X1119 = X1119 * ((10000 - X507)/10000) if (X1114 == 1 & X507 > 0)
quietly : replace X1120 = X1120 * ((10000 - X507)/10000) if (X1114 == 1 & X507 > 0)

quietly : replace farmbusiness = farmbusiness - X1130 * (X507/10000) if (X1125 == 1 & X507 > 0)
quietly : replace X1130 = X1130 * ((10000 - X507)/10000) if (X1125 == 1 & X507 > 0)
quietly : replace X1131 = X1131 * ((10000 - X507)/10000) if (X1125 == 1 & X507 > 0)

quietly : replace farmbusiness = farmbusiness - X1136 * (X507/10000) * ((X1108 * (X1103 == 1) + X1119 * (X1114 == 1) + X1130 * (X1125 == 1))/(X1108 + X1119 + X1130)) if (X1136 > 0 &(X1108 + X1119 + X1130) > 0 & X507 > 0)
quietly : replace X1136 = X1136 * ((10000-X507)/10000) * ((X1108 * (X1103 == 1) + X1119 * (X1114 == 1) + X1130 * (X1125 == 1)) / (X1108 + X1119 + X1130)) if (X1136 > 0 & (X1108 + X1119 + X1130) > 0 & X507 > 0)	

/* Value of primary residence */
gen houses = X604 + X614 + X623 + X716 + ((10000 - max(0,X507))/10000) * (X513 + X526)
 
/* NOTE : if R only owns a part of the property, the value reported should be only R's share */

/* Other residential real estate : includes land contracts / notes household has made, properties 
   other than principal residence that are coded as 1 - 4 family residences, time shares, and 
   vacation homes */

quietly : replace indi1 = (X1703 == 12 | X1703 == 14 | X1703 == 21 | X1703 == 22 | X1703 == 25 | X1703 == 40 | X1703 == 41 | X1703 == 42 | X1703 == 43 | X1703 == 44 | X1703 == 49 | X1703 == 50 | X1703 == 52 | X1703 == 999) 
quietly : replace indi2 = (X1803 == 12 | X1803 == 14 | X1803 == 21 | X1803 == 22 | X1803 == 25 | X1803 == 40 | X1803 == 41 | X1803 == 42 | X1803 == 43 | X1803 == 44 | X1803 == 49 | X1803 == 50 | X1803 == 52 | X1803 == 999)
//quietly : replace indi3 = (X1903 == 12 | X1903 == 14 | X1903 == 21 | X1903 == 22 | X1903 == 25 | X1903 == 40 | X1903 == 41 | X1903 == 42 | X1903 == 43 | X1903 == 44 | X1903 == 49 | X1903 == 50 | X1903 == 52 | X1903 == 999)

gen othresrealest = max(X1306,X1310) + max(X1325,X1329) + max(0,X1339) /*
	       */ + indi1 * max(0,X1706) * (X1705 / 10000) /*
	       */ + indi2 * max(0,X1806) * (X1805 / 10000) /*	       
		 */ + max(0,X2002)  



/* Net equity in nonresidential real estate : real estate other than principal residence, properties
   coded as 1 - 4 family residences, time shares, and vacation homes net of mortgages and other loans 
   taken out for investment real estate */

quietly : replace indi1 = (X1703 == 1 | X1703 == 2 | X1703 == 3 | X1703 == 4 | X1703 == 5 | X1703 == 6 | X1703 == 7 | X1703 == 10 | X1703 == 11 | X1703 == 13 | X1703 == 15 | X1703 == 24 | X1703 == 45 | X1703 == 46 | X1703 == 47 | X1703 == 48 | X1703 == 51 | X1703 == 53 | X1703 == -7) 
quietly : replace indi2 = (X1803 == 1 | X1803 == 2 | X1803 == 3 | X1803 == 4 | X1803 == 5 | X1803 == 6 | X1803 == 7 | X1803 == 10 | X1803 == 11 | X1803 == 13 | X1803 == 15 | X1803 == 24 | X1803 == 45 | X1803 == 46 | X1803 == 47 | X1803 == 48 | X1803 == 51 | X1803 == 53 | X1803 == -7)
//quietly : replace indi3 = (X1903 == 1 | X1903 == 2 | X1903 == 3 | X1903 == 4 | X1903 == 5 | X1903 == 6 | X1903 == 7 | X1903 == 10 | X1903 == 11 | X1903 == 13 | X1903 == 15 | X1903 == 24 | X1903 == 45 | X1903 == 46 | X1903 == 47 | X1903 == 48 | X1903 == 51 | X1903 == 53 | X1903 == -7)

gen nonresrealest = indi1 * max(0,X1706) * (X1705 / 10000) /*
	       */ + indi2 * max(0,X1806) * (X1805 / 10000) /*
	       */ + max(0,X2012) /*
	       */ - indi1 * X1715 * (X1705 / 10000) /*
	       */ - indi2 * X1815 * (X1805 / 10000) /*
	       */ - X2016
		

/* Remove installment loans for PURPOSE = 78 from non residential real estate 
   only where such property exsits, 
   otherwise if other real estate exists, include loan as residential debt, 
   otherwise treat as installment loan */

gen flag781 = 0 
quietly : replace flag781 = 1 if(nonresrealest != 0)
quietly : replace nonresrealest = nonresrealest - X2723 * (X2710 == 78) - X2740 * (X2727 == 78) - X2823 * (X2810 == 78) /*
		   */ - X2840 * (X2827 == 78) - X2923 * (X2910 == 78) - X2940 * (X2927 == 78) if (nonresrealest != 0)
	
	

*********************************************************************
* Business wealth and other non-financial wealth
*********************************************************************

/* For businesses where the household has an active interest, value is 
   net equity if business were sold today, plus loans from household to 
   business, minus loans from business to household not previously 
   reported, plus value of personal assets used as colleteral for business 
   loans that were reported earlier.
   For businesses where the household does not have an active interest, market
   value of the interest. */

gen business = max(0,X3129) + max(0,X3124) - max(0,X3126) * (X3127 == 5) + max(0,X3121) * (X3122 == 1| X3122 == 6) /*
	  */ + max(0,X3229) + max(0,X3224) - max(0,X3226) * (X3227 == 5) + max(0,X3221) * (X3222 == 1| X3222 == 6) /*
	  */ + max(0,X3335) + farmbusiness + max(0,X3408) + max(0,X3412) + max(0,X3416) + max(0,X3420) + max(0,X3452) + max(0,X3428)
	  
/* Other nonfinancial assets : defined as total value of miscellaneous assets minus other financial assets : 
   includes gold, silver (incl. silverware), other metals or metals NA type, jewlry, gem stones (incl. antiques), 
   cars (antiques or classic), antiques, furniture, art objects, paintings, sculputre, textile art, ceramic art, 
   photographs, (rare) books, coin collections, stamp collections, guns misc. real estate (exc. cemetery), 
   cemetery plots, china, figurines, crystal / glassware, musical instruments, livestock, horses, crops, 
   oriental rugs, furs, other collections (incl. baseball cards), records, wine, oil / gas /mineral leases or 
   investments, computer, equipment / tools, association or exchange membership, and other miscellaneous assets */	  
	  
gen othernonfinassets = X4022 + X4026 + X4030 - otherfinassets + X4018

*********************************************************************
* Totals
*********************************************************************

/* Total nonfinancial assets */
gen nonfinassets = vehicles + houses + othresrealest + nonresrealest + business + othernonfinassets

/* Total nonfinancial assets excluding principal residence */
gen nonfinassets_nohouses = nonfinassets - houses


/* Total assets */
gen assets = financialassets + nonfinassets


*********************************************************************
* Debt and related variables
*********************************************************************

/* Housing debt (mortgage, home equity loans and home equity line of credit (HELOC) -- 
   mopup line of credit (LOC) divided between home equity and other )*/

gen heloc = 0
gen mrthel = X805 + X905 + X1005 + 0.5 * (max(0,X1136)) * (houses > 0)
gen nh_mort = mrthel - heloc
	
quietly : replace heloc = X1108 * (X1103 == 1) + X1119 * (X1114 == 1) + X1130 * (X1125 == 1) /*
       */ + max(0,X1136) * (X1108 * (X1103 == 1) + X1119 * (X1114 == 1) + X1130 * (X1125 == 1))/(X1108 + X1119 + X1130) /* 
       */ if (X1108 + X1119 + X1130 >= 1)
quietly : replace mrthel = X805 + X905 + X1005 + X1108 * (X1103 == 1) + X1119 * (X1114 == 1) + X1130 * (X1125 == 1) /*
       */ + max(0,X1136) * (X1108 * (X1103 == 1) + X1119 * (X1114 == 1) + X1130 * (X1125 == 1))/(X1108 + X1119 + X1130) /*
       */ if (X1108 + X1119 + X1130 >= 1)
quietly : replace nh_mort = mrthel - heloc if (X1108 + X1119 + X1130 >= 1)

/* Home equity equals home value less amount still owed on 1st and 2nd/3rd mortgage and amount 
   owed on home equity lines of credit */
gen homeequity = houses - mrthel

/* Other lines of credit */
gen othloc = ((houses <= 0) + 0.5 * (houses > 0)) * (max(0,X1136))
quietly : replace othloc = X1108 * (X1103 != 1) + X1119 * (X1114 != 1) + X1130 * (X1125 != 1) /*
       */ + max(0,X1136) * (X1108 * (X1103 != 1) + X1119 * (X1114 != 1) + X1130 * (X1125 != 1))/(X1108 + X1119 + X1130) /*
       */ if (X1108 + X1119 + X1130 >= 1)
	
	
/* debt for other residential property: includes land contracts, residential property other than principal residence, 
   miscellaneous vacation, and installment debt reported for cottage / vacation home (code 67) */
/* NOTE : debt for non-residential real estate is netted out of the corresponding assets */

quietly : replace indi1 = (X1703 == 12 | X1703 == 14 | X1703 == 21 | X1703 == 22 | X1703 == 25 | X1703 == 40 | X1703 == 41 | X1703 == 42 | X1703 == 43 | X1703 == 44 | X1703 == 49 | X1703 == 50 | X1703 == 52 | X1703 == 53 | X1703 == 999) 
quietly : replace indi2 = (X1803 == 12 | X1803 == 14 | X1803 == 21 | X1803 == 22 | X1803 == 25 | X1803 == 40 | X1803 == 41 | X1803 == 42 | X1803 == 43 | X1803 == 44 | X1803 == 49 | X1803 == 50 | X1803 == 52 | X1803 == 53 | X1803 == 999)
//quietly : replace indi3 = (X1903 == 12 | X1903 == 14 | X1903 == 21 | X1903 == 22 | X1903 == 25 | X1903 == 40 | X1903 == 41 | X1903 == 42 | X1903 == 43 | X1903 == 44 | X1903 == 49 | X1903 == 50 | X1903 == 52 | X1903 == 53 | X1903 == 999)

gen mortgage1 = indi1 * X1715 * (X1705/10000) 
gen mortgage2 = indi2 * X1815 * (X1805/10000)
gen mortgage3 = 0

gen residentialdebt = X1318 + X1337 + X1342 + mortgage1 + mortgage2 + X2006


/* NOTE : See non residential real estate definition above for the definition of the flag and treatment of loans */
gen flag782 = 0
quietly : replace flag782 = 1 if(flag781 != 1 & othresrealest > 0)
quietly : replace residentialdebt = residentialdebt + X2723 * (X2710 == 78) + X2740 * (X2727 == 78) /*
	*/ + X2823 * (X2810 == 78) + X2840 * (X2827 == 78) + X2923 * (X2910 == 78) + X2940 * (X2927 == 78) /*
	*/ if (flag781 != 1 & othresrealest > 0)	

/* For parallel treatment, only include PURPOSE = 67 where other residential real estate is positive,
   otherwise treat as installment loan */
gen flag67 = 0
quietly : replace flag67 = 1 if (othresrealest > 0)
quietly : replace residentialdebt = residentialdebt + X2723 * (X2710 == 67) + X2740 * (X2727 == 67) /*
		*/ + X2823 * (X2810 == 67) + X2840 * (X2827 == 67) + X2923 * (X2910 == 67) + X2940 * (X2927 == 67) /*
		*/ if (othresrealest > 0)
	
/* Credit card debt */
/* NOTE : specific question addresses revolving debt at stores, and this amount is treated as credit card debt here */
/* Adjust for surveys before 1992 */
gen creditcard = max(0,X427) + max(0,X413) + max(0,X421) + max(0,X7575)

/* Buy now pay later 
   NOTE: from 2022 forward, specific question addresses revolving
   buy now pay later, and balance in these accounts are counted as debt. */
gen buynowpaylater = max(0, X443)
gen NObuynowpaylater = (X442 > 0 & X443 == -1)

/* Installment loans not specified elsewhere :
   subdivide into vehicle loans, education loans, and other installment loans */
/* Adjust for surveys before 1995 */
gen vehicleinstallment = X2218 + X2318 + X2418 + X7169 + X2424 + X2519 + X2619 + X2625
gen educationinstallment = X7824 + X7847 + X7870 + X7924 + X7947 + X7970 + X7179 /*
		     */ + X2723 * (X2710 == 83) + X2740 * (X2727 == 83) /*
		     */ + X2823 * (X2810 == 83) + X2840 * (X2827 == 83) /*
		     */ + X2923 * (X2910 == 83) + X2940 * (X2927 == 83)
		 
			 
gen installment = vehicleinstallment + X7183 + X7824 + X7847 + X7870 + X7924 + X7947 + X7970 + X7179 + X1044 + X1215 + X1219 + buynowpaylater


/* NOTE : See non residential real estate and residential debt definition above for the definition of the flags and treatment of loans */

quietly : replace installment = installment /*
	 */ + X2723 * (X2710 == 78) + X2740 * (X2727 == 78) /*
         */ + X2823 * (X2810 == 78) + X2840 * (X2827 == 78) /*
         */ + X2923 * (X2910 == 78) + X2940 * (X2927 == 78) /*
         */ if (flag781 == 0 & flag782 == 0)

quietly : replace installment = installment /*
	 */ + X2723 * (X2710 == 67) + X2740 * (X2727 == 67) /*
         */ + X2823 * (X2810 == 67) + X2840 * (X2827 == 67) /*
         */ + X2923 * (X2910 == 67) + X2940 * (X2927 == 67) /*
         */ if (flag67 == 0)

	
quietly : replace installment = installment /*
			 */ + X2723 * (X2710 != 67 & X2710 != 78) + X2740 * (X2727 != 67 & X2727 != 78) /*
		         */ + X2823 * (X2810 != 67 & X2810 != 78) + X2840 * (X2827 != 67 & X2827 != 78) /*
		         */ + X2923 * (X2910 != 67 & X2910 != 78) + X2940 * (X2927 != 67 & X2927 != 78)
		         
gen otherinstallment = installment - vehicleinstallment - educationinstallment		       


/* Margin loans */
/* Adjust in 1995 survey */
gen marginloan = max(0,X3932)

/* Pension loans not reported earlier */
/* Adjust in surveys before 2004 */
gen pensionloan1 = max(0,X11027) * (X11070 == 5)
gen pensionloan2 = max(0,X11127) * (X11170 == 5)
gen pensionloan3 = 0
gen pensionloan4 = max(0,X11327) * (X11370 == 5)
gen pensionloan5 = max(0,X11427) * (X11470 == 5)
gen pensionloan6 = 0

/* other debts : loans against pensions, loans against life insurance, margin loans, miscellaneous */
gen otherdebt = pensionloan1 + pensionloan2 + pensionloan4 + pensionloan5 + pensionloan6 /*
	   */ + max(0,X4010) + max(0,X4032) + marginloan


/* Total debt */
gen debt = mrthel + residentialdebt + othloc + creditcard + installment + otherdebt
/* Generate debt without housing debt */
gen debt_nh = debt - mrthel

/* Total net worth */
gen networth = assets - debt


/* Drop initial data */
keep id pers impl wgt wgt1 age* sex race educ* married kids householdsize lfpart lifecycle occat industry /*
 */ `incomeclasses' paidwork unemployed unemplduration *hoursworked* *weeksworked* *annualhours* expectedtenure employer* /*
 */ checking prepaid saving moneymarket_deposit moneymarket_mutualfunds moneymarket callaccount liquidassets /*
 */ certdeposit mutualfunds stocks nontaxbonds mortagebonds govtbonds otherbonds bonds financialassets irakeogh /*
 */ thrift pensionequity futurepension currentpension retireliquidassets savingbonds cashlifeinsurance annuities /*
 */ trusts othermgdinvest otherfinassets directequity retireequity equity equity2income vehicles valueown valueleased /*
 */ farmbusiness houses homeequity othresrealest nonresrealest business othernonfinassets nonfinassets othloc /*
 */ nonfinassets_nohouses assets residentialdebt creditcard buynowpaylater NObuynowpaylater vehicleinstallment /*
 */ educationinstallment installment otherinstallment marginloan pensionloan1 pensionloan2 pensionloan3 pensionloan4 /*
 */ pensionloan5 pensionloan6 otherdebt debt debt_nh networth mrthel heloc spouseincome* headincome* pensionwithdrawal /*
 */ health* employmentstatus*
local adjustlist1 "`incomeclasses' checking prepaid saving moneymarket_deposit moneymarket_mutualfunds moneymarket callaccount"
local adjustlist2 "liquidassets certdeposit mutualfunds stocks nontaxbonds mortagebonds govtbonds otherbonds bonds"
local adjustlist3 "financialassets irakeogh thrift pensionequity futurepension currentpension retireliquidassets"
local adjustlist4 "savingbonds cashlifeinsurance annuities trusts othermgdinvest otherfinassets directequity"
local adjustlist5 "retireequity equity vehicles valueown valueleased farmbusiness houses homeequity othresrealest"
local adjustlist6 "nonresrealest business othernonfinassets nonfinassets nonfinassets_nohouses assets residentialdebt"
local adjustlist7 "creditcard vehicleinstallment educationinstallment installment otherinstallment marginloan othloc"
local adjustlist8 "pensionloan1 pensionloan2 pensionloan3 pensionloan4 pensionloan5 pensionloan6 otherdebt debt debt_nh"
local adjustlist9 "networth mrthel heloc spouseincome headincome spouseincome2nd headincome2nd pensionwithdrawal" 


forvalues j = 1(1)9 {
	/* CPI Adjustment to current base dollars */
	local numvars : word count `adjustlist`j'' 
	local i = 1
	while `i' <= `numvars' {
		local kvar : word `i' of `adjustlist`j''
		quietly : replace `kvar' = `kvar' * $cpiadj
		local i = `i' + 1
		}
	}
	
/* Save generated dataset for analysis */
save ${datadir}2022/scf2022wealth, replace


