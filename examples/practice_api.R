# Learn about Census API for data access

# Load necessary libraries

pkgs_api <- c("tidycensus", "tidyverse", "patchwork")

invisible(lapply(pkgs_api, library, character.only = TRUE))


# Key Variables for us to look at, you can get more at:

# ACS 1-year 2024: https://api.census.gov/data/2024/acs/acs1/subject/variables.html
# ACS 5-year 2024: https://api.census.gov/data/2024/acs/acs5/subject/variables.html
# Decennial: https://api.census.gov/data/2020/dec/dhc/variables.html
# All datasets available: https://api.census.gov/data.html

# Decennial variables to plug in

# Decennial population data

pop_dec <- get_decennial(
    geography = "county",
    variables = "P1_001N",
    year = 2020,
    show_call = TRUE)


# ACS Variables to plug in

TOTAL_POP <- "B01003_001E"
TOTAL_SEX_BY_AGE <- "B01001_001E"
TOTAL_SEX_BY_AGE_MALE <- "B01001_002E"
TOTAL_SEX_BY_AGE_FEMALE <- "B01001_026E"
MEDIAN_HOUSEHOLD_INCOME_VARIABLE <- "B19013_001E"
MEDIAN_HOME_VALUE  <- "B25077_001E"
MEDIAN_GROSS_RENT <- "B25064_001E"
POVERTY_POP <- "B17001_002E"
RENTERS <- c("B25070_007E", "B25070_008E", "B25070_009E","B25070_010E")
BACH_DEGREE <- "B15003_022E"
WORK_TRAVEL <- "B08301_010E"


# ACS Population data

acs_total_pop = get_acs(
    # Data set default: American Community Survey 5-Year
    survey = "acs5", 
    # Year: 2024
    year=2024,
    # Variable: total population and MOE
    variables= c("NAME", TOTAL_POP, "B01003_001M"),
    # Geography: All States
    geography = "state",
    # Show URL for data call
    show_call = TRUE)

acs_total_pop


# ACS Income data, one state

acs_wa_income = get_acs(
    # Data set: American Community Survey 1-Year
    survey = "acs1",   
    # Year: 2022
    year=2022,
    # Variable: median household income and MOE
    variables= c("NAME", MEDIAN_HOUSEHOLD_INCOME_VARIABLE, "B19013_001M"),
    # Geography: States level
    geography = "state",
    # Which state
    state = "WA",
    # Show URL for data call
    show_call = TRUE)

acs_wa_income


# ACS Poverty data, all states

acs_states_poverty = get_acs(
    # Data set default: American Community Survey 5-Year
    survey = "acs5",
    # Year: 2024
    year=2024,
    # Variable: Name and poverty population
    variables= c("NAME", POVERTY_POP, "B17001_002M"),
    # Geography: State level
    geography = "state",
    # Show URL for data call
    show_call = TRUE)

acs_states_poverty


# ACS Two variables, tract level

acs_east_coast_vars = get_acs(
    # Data set default: American Community Survey 5-Year
    survey = "acs5",
    # Year: 2021
    year = 2021,
    # Variable: Bachelor Degree and Work Travel
    variables= c("NAME", BACH_DEGREE, WORK_TRAVEL),
    # Geography: tract level
    geography = "tract",
    # Six states this time.
    state= c("MD", "VA", "DC", "DE", "WV", "PA"),
    # Show URL for data call
    show_call = TRUE)

acs_east_coast_vars


# ACS Earlier data, county level

acs_west_coast_income = get_acs(
    # Data set default: American Community Survey 5-Year
    survey = "acs5",
    # Year: 2015
    year=2015,
    # Name and median household income
    variables=c("NAME", MEDIAN_HOUSEHOLD_INCOME_VARIABLE, "B19013_001M"),
    # Geography: county level
    geography = "county",
    # Three states this time.
    state= c("WA", "OR", "CA"),
    # Show URL for data call
    show_call = TRUE)

acs_west_coast_income


# ACS DMV Population

acs_dmv_population = get_acs(
    # Data set default: American Community Survey 5-Year
    survey = "acs5",
    # Year: 2024
    year=2024,
    # Variable: total sex by age
    variables=c("NAME", TOTAL_SEX_BY_AGE, TOTAL_SEX_BY_AGE_MALE, TOTAL_SEX_BY_AGE_FEMALE),
    # Geography: county level
    geography = "county",
    # DMV Area
    state= c("MD", "VA", "DC", "DE", "WV", "PA"),
    # Show URL for data call
    show_call = TRUE)

acs_dmv_population


# Follow the articles for more examples: https://walker-data.com/tidycensus/