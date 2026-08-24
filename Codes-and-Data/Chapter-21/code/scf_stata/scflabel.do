label data "Wealth and Income information from the Survey of Consumer Finances (${baseyear} dollars)"

label variable id "Case id"
label variable impl "Id for the implicate"
label variable pers "Person identifier across implicates"
label variable wgt "Weight if used with a single implicate"
label variable wgt1 "Weight if used with all implicates"

label variable age "Age of household head"
label variable agecl "Age class"
forvalues i = 1(1)12 {
	label variable agemember`i' "Age of household member in 1989 rounded to nearest 5 years"
	}
label variable sex "Sex of household head"
label define sexlabel 1 "Male" 2 "Female"
label values sex sexlabel

label define healthlabel 1 "excellent" 2 "good" 3 "fair" 4 "poor" 0 "inap"
label values healthhead healthspouse healthlabel

label define agecllabel 1 " 1 : < 35 "
label define agecllabel 2 " 2 : 35 - 44 ", add
label define agecllabel 3 " 3 : 45 - 54 ", add
label define agecllabel 4 " 4 : 55 - 64 ", add
label define agecllabel 5 " 5 : 65 - 74 ", add
label define agecllabel 6 " 6 : >= 75 ", add
label values agecl agecllabel

label variable educ "Education in years"
label variable educl "Education class"
label define educllabel 1 " 1 : no high school"
label define educllabel 2 " 2 : high school", add
label define educllabel 3 " 3 : some college", add
label define educllabel 4 " 4 : college degree", add
label values educl educllabel

label variable race "Race of household head"
label define racelabel 1 " 1 : white non-Hispanic"
label define racelabel 2 " 2 : black/African-American", add
label define racelabel 3 " 3 : Hispanic", add
label define racelabel 4 " 4 : other", add
label values race racelabel

label variable employersizehead "Employees of head's employer" 
label variable employersizespouse "Employees of spouse's employer" 
label define employersize 1 " 1 : Fewer than 10"
label define employersize 2 " 2 : 10 to 19", add
label define employersize 3 " 3 : 20 to 99", add
label define employersize 4 " 4 : 100 to 499", add
label define employersize 5 " 5 : 500 or more", add
label define employersize 0 " 0 : inap", add
label values employersizehead employersizespouse employersize

label variable employertenurehead "Head total years with employer/business" 
label variable employertenurespouse "spouse total years with employer/business" 


label variable married "Marital status"
label define marriedlabel 1 " 1 : married"
label define marriedlabel 2 " 2 : not married", add
label values married marriedlabel
label variable kids "Number of children in the household"
label variable householdsize "Household size (OECD scale)"

label variable lfpart "Labor force participation indicator"
label define lflabel 0 " 0 : not working at all"
label define lflabel 1 " 1 : working in some way", add
label values lfpart lflabel

label variable lifecycle "Lifecycle status"

label define lclabel 1 " 1 : < 55, not married , no children"
label define lclabel 2 " 2 : < 55, married , no children", add
label define lclabel 3 " 3 : < 55, married , children", add
label define lclabel 4 " 4 : < 55, not married, children", add
label define lclabel 5 " 5 : >= 55, working", add
label define lclabel 6 " 6 : >= 55, not working", add
label values lifecycle lclabel

label variable employmentstatushead "current employment status head"
label variable employmentstatusspouse "current employment status spouse" 
label define employmentstatus 11 "worker only"
label define employmentstatus 12 "Worker + disabled", add
label define employmentstatus 13 "Worker + retired", add
label define employmentstatus 14 "Worker + student", add
label define employmentstatus 15 "Worker + homemaker", add
label define employmentstatus 16 "Worker + unemployed", add
label define employmentstatus 17 "Worker + temporarily laid off", add
label define employmentstatus 20 "Temporarily laid off", add
label define employmentstatus 21 "Temporarily laid off", add
label define employmentstatus 22 "On sick, maternity leave", add
label define employmentstatus 23 "On sick, maternity leave", add
label define employmentstatus 24 "On sabbatical", add
label define employmentstatus 30 "Unemployed, looking for work", add
label define employmentstatus 50 "Retired only", add
label define employmentstatus 52 "Disabled only", add
label define employmentstatus 70 "Student only", add
label define employmentstatus 80 "Homemaker and other NILF", add
label define employmentstatus 85 "Unpaid volunteer", add
label define employmentstatus 90 "Unpaid family workers", add
label define employmentstatus 96 "other", add
label define employmentstatus 97 "other", add
label define employmentstatus -7 "unknown", add
label values employmentstatushead employmentstatusspouse employmentstatus

label variable occat "Occupational status"

label define oclabel 1 " 1 : work for someone else"
label define oclabel 2 " 2 : self-employed ", add
label define oclabel 3 " 3 : retired, student, homemaker, and age 65 or older", add
label define oclabel 4 " 4 : out of the labor force", add
label values occat oclabel

label variable industry "Sector of employment (Change of codes in 2022)"


label define indlabel 1 " 1 : Agriculture, Forestry, Fishing and Hunting "
label define indlabel 2 " 2 : Mining", add
label define indlabel 3 " 3 : Manufactoring", add
label define indlabel 4 " 4 : Trade and Restaurants", add
label define indlabel 5 " 5 : Rental, Software, and Maintenance", add
label define indlabel 6 " 6 : Utilities, Finance, Services  ", add
label define indlabel 7 " 7 : Public Administration and Armed Forces", add
label values industry indlabel

/* Income categories */
label variable income "Household income in the previous calender year"
label variable norminc "Household's self reported normal income"
label variable laborincome "Wages and salaries"
label variable unemployment "Unemployment or worker's compensation"
label variable otherincome "Other sources of income"
label variable socialsecurity "Income from Social Security"
label variable capitalgains "Net capital gains or losses"
label variable intdivincome "Interest and dividend income"
label variable busifarmincome "Business or farm income"

/* Labor market */
label define yesno 5 "no" 1 "yes"
label variable headhoursworked "head hours worked main job normal week"
label variable headweeksworked "head weeks worked main job incl paid vacations and sick leave"
label variable headannualhours "head annual hours worked (hoursworked * weeksworked)"
label variable spousehoursworked "spouse hours worked main job normal week"
label variable spouseweeksworked "spouse weeks worked main job incl paid vacations and sick leave"
label variable spouseannualhours "spouse annual hours worked (hoursworked * weeksworked)"
label variable paidwork "work for pay at the present time (head)"
label values paidwork yesno 
label variable unemployed "unemployed during past 12 month (head)"	
label values unemployed yesno
label variable unemplduration "total unemployed duration over past 12 month (head)"		

/* Wealth categories */
label variable networth "Total net worth"
label variable assets "Total assets (financial and non financial)"
label variable financialassets "Total financial assets"
label variable creditcard  "Credit card debt"
label variable mrthel  "mortgage and home equity loans"
label variable heloc  "Home equity line of credit"


