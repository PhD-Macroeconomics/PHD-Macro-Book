## Computing International Business Cycle Statistics

### Marina Azzimonti

### Data Preparation

The data was obtained from the Development Indicators (WDI) database, accessible via the [World Bank Databank](https://databank.worldbank.org/source/world-development-indicators). It was accessed on Dec 11, 2024 and recorded in the Excel file: `World_Development_Indicators_ALL_12_8.xlsx`. Each series corresponds to a specific variable, identified using the `SeriesName` column.

The variables used are:

- `cy`: Households and NPISHs final consumption expenditure (% of GDP)
- `y_p`: GDP per capita, PPP (constant 2021 international \$)
- `y_nom`: GDP per capita (current LCU)
- `gy`: General government final consumption expenditure (% of GDP)
- `my`: Imports of goods and services (% of GDP)
- `xy`: Exports of goods and services (% of GDP)
- `pop`: Population, total
- `tt`: Net barter terms of trade index (2015 = 100)
- `rer`: Real effective exchange rate index (2010 = 100)
- `invy`: Gross fixed capital formation (% of GDP)
- `CAy`: Current account balance (% of GDP)
- `y`: GDP per capita (constant LCU)

### Derived Variables

Several new variables were constructed using the base data:

**Per Capita and Real Terms**:
Household consumption (`cy`), government consumption (`gy`), imports (`my`), exports (`xy`), and gross fixed capital formation (`invy`) were transformed into real per capita terms by multiplying with `y` (real GDP per capita).

**Trade and Current Account Variables**:
`tby`: Trade balance was created as exports minus imports: tb=x-m and `CA`: Current account in real terms calculated as `CAy * y`.
`open`: Openness (as a percentage of GDP) was computed as `xy + my`.

### Country Coverage

- **Advanced Economies (D)**: Estonia, Italy, Switzerland, Sweden, Singapore, Canada, Malta, Denmark, United Kingdom, Cyprus, Norway, Czechia, Slovak Republic, Australia, France, Netherlands, Israel, Slovenia, Spain, Finland, Korea, Rep., Portugal, Germany, Iceland, United States.

- **Emerging Markets (EM)**: Armenia, Brazil, Turkiye, Panama, Tunisia, Uruguay, South Africa, Honduras, Namibia, Thailand, Belize, Ukraine, Oman, Mexico, Pakistan, Bahrain, Argentina, Venezuela, RB, China, Romania, Seychelles, Chile, Peru, Barbados, El Salvador, Egypt, Arab Rep., Malaysia, Mauritius, Saudi Arabia, Jordan, Costa Rica, Bolivia, Dominican Republic, Ecuador, Russian Federation, Belarus, Indonesia, Albania, Jamaica, Mongolia, Colombia, Syrian Arab Republic, Morocco, Hungary, Botswana, Fiji, Guatemala, Vanuatu, India, Bulgaria, Paraguay.

- **Low-income and Developing Countries (U)**: Sudan, Tanzania, Congo, Rep., Eswatini, Niger, Kenya, Madagascar, Bangladesh, Kyrgyz Republic, Guinea, Nepal, Benin, Mali, Uganda, Togo, Ghana, Senegal, Burundi, Cameroon, Cambodia.

### Data Cleaning

To be included in the annual dataset, a country must have at least 30 years of consecutive annual observations for the variables `y`, `c`, `g`, `i`, `x`, and `m`.

Certain countries and years were excluded due to data quality or "jumps" in data coverage (we can only de-trend observations that are consecutive). 

We only keep observations from 1970 onwards, as there are too few countries with data prior to that year.

**HP-Filtered Variables**: Variables were decomposed into trend and cyclical components using the Hodrick-Prescott (HP) filter with a smoothing parameter of 100. The variables include:

- Log-transformed GDP (`ln_y`), consumption (`ln_c`), investment (`ln_inv`), exports (`ln_x`), imports (`ln_m`), and government expenditure (`ln_g`).
- HP-filtered components (e.g., `hp_ln_y` for log-GDP). Trade balance (`tb`) and current account (`CA`) were scaled by the trend component of GDP in levels and then HP-filtered.

### Population Weights

**Weight Construction**:
Average population per country was computed and scaled to create weights for each region:

- `country_weight`: Weight based on global population.
- `country_weight_D`, `country_weight_EM`, `country_weight_U`: Weights for Advanced Economies, Emerging Markets, and Low-income and Developing countries, respectively.

**Weighted Statistics**:
Standard deviations, autocorrelations, and correlations were computed using these weights.

### Statistical Measures

**Standard Deviations**:
Standard deviations of HP-filtered variables were computed for each country. Ratios relative to GDP deviations (e.g., `sdc_sdy`: Standard deviation of consumption relative to GDP) were calculated.

**Correlations**:
Correlations between HP-filtered variables (e.g., consumption and GDP) were computed for each country. Regional averages were calculated using population weights.

**Autocorrelations**:
First-order autocorrelations were computed for each variable within each country.

### Outputs

**LaTeX Tables**:
Summary tables for standard deviations, correlations, and autocorrelations were generated using `esttab` in Stata and exported to `.tex` files for inclusion in the manuscript.

**Final Dataset**:
The final dataset (`std_correl.dta`) includes country-level and regional-level statistics for the analysis.

## Other Series
GDP per capita, current prices U.S. dollars (world map and time trend) obtained from IMF site:
https://www.imf.org/external/datamapper/NGDPDPC@WEO/OEMDC/ADVEC/WEOWORLD/USA

World GDP in Trillions of 2015 U$: NY.GDP.MKTP.KD

https://databank.worldbank.org/reports.aspx?source=2&series=NY.GDP.MKTP.CD&country
