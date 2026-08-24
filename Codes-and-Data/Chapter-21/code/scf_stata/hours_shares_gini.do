/*==============================================================
  hours_shares_gini.do

  Table 21.1, the two "Hours worked" rows, and their Gini
  coefficients.

  WHY THIS FILE EXISTS
  --------------------
  QR2022_nh.do produces the Earnings, Income and Wealth rows of
  Table 21.1 (and their Ginis, via sgini).  It contains no hours
  variables at all.  The tabulation that produced the two hours
  rows in the published chapter was done separately and has not
  survived; this file is a reconstruction written for the
  replication package so that the row is at least computable.

  READ THE WARNING IN THE README BEFORE USING THE OUTPUT.
  This program does NOT reproduce the shares printed in the
  chapter.  See "The two hours rows" in README.md, which gives
  the printed numbers, the numbers this program produces, and
  what is known about the gap.  The Gini coefficients printed in
  the chapter (0.30 and 0.14) were recovered from the published
  shares themselves, not from this program -- see
  ../gini_from_shares.py.

  INPUT   scf2022.dta, the analysis file written by
          makeupdata_nh.do.  The SCF Summary Extract (SCFP2022.csv)
          cannot be used: it carries no hours variables.
  OUTPUT  ${resdir}hours_shares_gini.txt

  Hours definitions follow makeupdata_nh.do exactly:
      headannualhours   = weeks*hours, main job + second job,
                          weekly hours truncated at 95
      spouseannualhours = same for the spouse
  Weight is wgt1 = X42001/5, i.e. all five implicates pooled,
  the same weight QR2022_nh.do uses.
==============================================================*/

clear all
set more off
set maxvar 10000

/* ---- paths: edit these two, as for every do-file here ------ */
global master1 = "/path/to/scf_update/"
global resdir  = "${master1}results/"
global qrdata  = "${master1}data/"

capture log close
log using "${resdir}hours_shares_gini.log", replace text

use "${qrdata}2022/scf2022wealth", clear

/*---------------------------------------------------------------
  1. Hours variables
---------------------------------------------------------------*/
/* makeupdata_nh.do already stores headannualhours and
   spouseannualhours with the second job folded in.            */
capture confirm variable headannualhours
if _rc {
    display as error "headannualhours not found -- run makeupdata_nh.do first"
    exit 111
}

gen double hours_hh = headannualhours + spouseannualhours
label variable hours_hh "annual hours worked, head + spouse"

/* Per person: head and spouse as separate observations.        */
preserve

/*---------------------------------------------------------------
  2. Group shares and Gini, per household
---------------------------------------------------------------*/
tempname H
postfile `H' str12 unit str8 group double share using "${resdir}_hours_tmp", replace

local groups "0 1 1 5 5 10 0 20 20 40 40 60 60 80 80 100 90 95 95 99 99 100"

quietly {
    /* cumulative weight ranking on hours */
    sort hours_hh
    gen double cw = sum(wgt1)
    quietly sum wgt1
    replace cw = 100 * cw / r(sum)
    quietly sum hours_hh [aw = wgt1]
    local tot = r(sum_w) * r(mean)

    local n : word count `groups'
    forvalues k = 1(2)`n' {
        local lo : word `k' of `groups'
        local kk = `k' + 1
        local hi : word `kk' of `groups'
        quietly sum hours_hh [aw = wgt1] if cw > `lo' & cw <= `hi'
        local s = 100 * r(sum_w) * r(mean) / `tot'
        post `H' ("per household") ("`lo'-`hi'") (`s')
    }
    drop cw
}

sgini hours_hh [aw = wgt1]
local gini_hh = r(coeff)

/*---------------------------------------------------------------
  3. Group shares and Gini, per person
---------------------------------------------------------------*/
restore
preserve

keep id wgt1 headannualhours spouseannualhours
rename headannualhours   h1
rename spouseannualhours h2
reshape long h, i(id) j(member)
rename h hours_pp
drop if missing(hours_pp)

quietly {
    sort hours_pp
    gen double cw = sum(wgt1)
    quietly sum wgt1
    replace cw = 100 * cw / r(sum)
    quietly sum hours_pp [aw = wgt1]
    local tot = r(sum_w) * r(mean)

    local n : word count `groups'
    forvalues k = 1(2)`n' {
        local lo : word `k' of `groups'
        local kk = `k' + 1
        local hi : word `kk' of `groups'
        quietly sum hours_pp [aw = wgt1] if cw > `lo' & cw <= `hi'
        local s = 100 * r(sum_w) * r(mean) / `tot'
        post `H' ("per person") ("`lo'-`hi'") (`s')
    }
    drop cw
}

sgini hours_pp [aw = wgt1]
local gini_pp = r(coeff)

postclose `H'
restore

/*---------------------------------------------------------------
  4. Report
---------------------------------------------------------------*/
use "${resdir}_hours_tmp", clear
list, noobs sepby(unit)

display ""
display "Gini, hours per household : " %6.3f `gini_hh'
display "Gini, hours per person    : " %6.3f `gini_pp'
display ""
display "Chapter prints 0.30 and 0.14, recovered from the published"
display "shares (see ../gini_from_shares.py).  If the numbers above"
display "differ materially, that is the known and documented gap --"
display "see README.md, section 'The two hours rows'."

erase "${resdir}_hours_tmp.dta"
log close
