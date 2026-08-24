# The two hours rows of Table 21.1 — CPS ASEC

These two scripts produce the "Hours worked" rows of Table 21.1. They
replace the earlier SCF-based reconstruction (`../scf_stata/
hours_shares_gini.do`), which was the wrong survey.

## Getting the data

The microdata is the Census Bureau's CPS ASEC public use file. **No
registration and no IPUMS account are needed:**

```
https://www2.census.gov/programs-surveys/cps/datasets/2023/march/
  asecpub23csv.zip            person / family / household CSVs (150 MB)
  asec2023_ddl_pub_full.pdf   data dictionary
  persfmt.txt                 person-record layout
```

Download and unzip into this directory, then run

```
python hours_shares_asec.py     # the rows, plus six sample variants
python verify_rows.py           # independent recomputation, must PASS
```

ASEC 2023 covers **calendar year 2022**, matching the rest of the table.
The raw file is not committed here because of its size.

## Construction

Annual hours = `HRSWK` × `WKSWORK`, weighted by `MARSUPWT` for persons
and `HSUP_WGT` for households (both weights carry two implied decimals
in the public-use CSV). These are the raw-Census names for the IPUMS
variables used by Boppart, Krusell and Olsson (2024, Table 3):

| BKO / IPUMS | Raw Census ASEC | Position in `persfmt.txt` |
|---|---|---|
| `UHRSWORKLY` | `HRSWK` | 296 |
| `WKSWORK1` | `WKSWORK` | 338 |
| `ASECWT` | `MARSUPWT` (÷100) | 71 |
| `INCWAGE` | `WSAL_VAL` | 422 |
| `AGE` / `SEX` | `A_AGE` / `A_SEX` | 79 / 92 |

Entries are each group's mean hours **relative to the overall mean**,
so 1.00 is the average and the five quintiles sum to 5 — the same
convention as the earnings, income and wealth rows. Both rows cover the
whole population, non-workers included, again matching the rows above
(the Earnings row carries a negative bottom quintile, so it plainly
includes households with no earnings).

Published rows, as they appear in the book:

| | 0-1 | 1-5 | 5-10 | 0-20 | 20-40 | 40-60 | 60-80 | 80-100 | 90-95 | 95-99 | 99-100 | Gini |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| per person | 0.00 | 0.00 | 0.00 | 0.00 | 0.04 | 1.18 | 1.74 | 2.04 | 2.09 | 2.40 | 3.20 | 0.48 |
| per household | 0.00 | 0.00 | 0.00 | 0.00 | 0.41 | 0.92 | 1.49 | 2.18 | 2.15 | 2.68 | 3.83 | 0.46 |

"Per person" is every adult aged 16 and over; "per household" is total
hours summed over all household members. Mean annual hours are 1,198
and 2,356 respectively, consistent with each other at 2.03 adults per
household. The zeros in the first four columns are correct: 36 percent
of adults and 25 percent of households do no market work at all, so the
bottom groups hold a zero share of total hours.

`verify_rows.py` recomputes both rows by a different route — group mean
over grand mean, with fractional weight at the group boundaries,
instead of share over population share — and asserts the two agree to
within 0.006 per cell.

## Note on the first-proof version of this table

The first proofs printed these rows as **percent shares** rather than
ratios, and printed 7.65 in the per-household 99-100 cell. That value
is not attainable: it implies the top 1 percent of households work 7.65
times the average, or about 24,000 hours a year each, where the most
extreme household in the entire survey works 22,048. Both the units and
that entry were corrected before publication.
