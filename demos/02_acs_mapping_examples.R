# Mental Model for working with the Census API

# Every tidycensus call is a structured API query that returns a data frame.

# Every Census API call is:
##   a dataset + a geography + variables + filters = a table

# Every Census map is: 
##   a data call + shapefile + join = geographic visualization

# We will repeat this pattern across multiple datasets.

# For more geography functions/options: 
# https://walker-data.com/census-r/an-introduction-to-tidycensus.html#geography-and-variables-in-tidycensus


# Load our packages, which were installed in the setup file

# For Census Data

library(tidycensus) # ACS, Decennial 
library(censusapi) # All other Census datasets

# For Census shapefiles

library(tigris)

# For working with the data and visualization

library(dplyr)
library(tidyr)
library(ggplot2)

# For interactive maps

library(mapview)

# For map/visual formatting and composition

library(patchwork)

# For number formatting helpers

library(scales)

# Disable scientific notation

options(scipen = 999)

# Use tigris cache to avoid redownloading shapefiles, optional

options(tigris_use_cache = TRUE)


# First, lets take a look at the available datasets

apis <- listCensusApis()   # Get general information about available datasets

View(apis) #1788 api options


# Lets filter it down to ACS related only

ACS_api <- apis %>%
    filter(grepl("ACS", name, ignore.case = TRUE))  # 273 ACS related API options

table(ACS_api$vintage) # We have data available since 2004


# Next, lets look at the available variables within a dataset

ACS5_24_vars <- load_variables(2024, "acs5")

tail(ACS5_24_vars, 20)

# Additional examples on how to use this function:

ACS1_23_vars <- load_variables(2023, "acs1")
ACS1_13_vars <- load_variables(2013, "acs1")
ACS5_22_vars <- load_variables(2022, "acs5")



# Example 1: Mapping State Population Estimates from the ACS
    
## Step 1: Data call to the Census API

# See additional geography options: http://api.census.gov/data/2024/acs/acs1/geography.json
# See additional variable options: http://api.census.gov/data/2024/acs/acs1/variables.json

pop_acs <- get_acs(
    geography = "state",
    variables = c("B01001_001E",    # Total Population by State
                  "B01001_002E",    # Male Population by State
                  "B01001_026E"),   # Female Population by State
    year = 2024, 
    survey= "acs1",
    show_call = TRUE)                   # show the URL 


## Step 2: Get your shapefile from tigris

states_sf <- states(year = 2024)


## Step 3: Join the data and shapefile

map_pop_acs <- left_join(states_sf, 
                         pop_acs, 
                         by = "GEOID")


## Step 4: Visualization, create a map

ggplot(map_pop_acs) +
    geom_sf(aes(fill = estimate)) +
    scale_fill_viridis_c(direction = -1,
                         labels = label_comma(accuracy = 1)) +
    labs(title = "Total Population Distribution Across the United States",
         caption = "Source: American Community Survey 1-year Estimate 2024")

# note that this is the standard view, but this is not the Census standard view,
# we will see a geography shift in Example 3



# Example 2: Creating Interactive Population Maps with mapview

## Step 1: Data call to the Census API,with a wide output for mapview

pop_acs_wide <- get_acs(
    geography = "state",
    variables = c("B01001_001E",    # Total Population by State
                  "B01001_002E",    # Male Population by State
                  "B01001_026E"),   # Female Population by State
    year = 2024, 
    survey= "acs1",
    output = "wide",
    show_call = TRUE)  

## Step 2: Join your shapefile and your data

map_pop_acs_wide <- left_join(states_sf, 
                              pop_acs_wide, 
                              by = "GEOID")

## Step 3: Visualize using mapview for an interactive view

mapview((map_pop_acs_wide %>% 
             select(c("NAME.y", 
                      "REGION",
                      "B01001_001E",
                      "B01001_002E",
                      "B01001_026E")) %>%
             mutate(B01001_001E = number(B01001_001E, big.mark = ",", accuracy = 1),
                    B01001_002E = number(B01001_002E, big.mark = ",", accuracy = 1),
                    B01001_026E = number(B01001_026E, big.mark = ",", accuracy = 1)) %>%
             dplyr::rename(State = NAME.y,
                    Region = REGION,
                    Total = B01001_001E,
                    'Total Males' = B01001_002E,
                    'Total Females' = B01001_026E) %>%
             mutate(Region = case_when(
                 Region == "1" ~ "Northeast",
                 Region == "2" ~ "Midwest", 
                 Region == "3" ~ "South",
                 Region == "4" ~ "West"))), 
        zcol = "Region", 
        layer.name = "Region")


# Example 3: Mapping ACS Population Estimates with Built-In Geography

## Step 1: Data call to the Census API with geometry included, and shift it to a Census standard

pop_acs_geo <- get_acs(
    geography = "state",
    variables = "B01001_001",
    geometry = TRUE,   # bring the geometry in during the data call, tidycensus makes this possible
    year = 2024,      
    survey= "acs1",
    show_call = TRUE) %>% 
    shift_geometry() %>%  # shift_geometry gives us the census standard view, pay attention to the difference
    rename(Estimate = estimate)

## Step 2: Visualization, we don't need to get the shapefile since we have geometry in our data call

ggplot(pop_acs_geo) +
    geom_sf(aes(fill = estimate)) +
    scale_fill_viridis_c(direction = -1,
                         labels = label_comma(accuracy = 1)) +
    labs(title = "State Population Estimates Using Shifted Geometries",
         caption = "Source: American Community Survey 1-year Estimate 2024")



# Example 4: Mapping 2020 Decennial Census Population by County
    
## Step 1: Data call to the Census API

pop_dec <- get_decennial(
    geography = "county",
    variables = "P1_001N",
    year = 2020,
    show_call = TRUE)


## Step 2: shapefile from tigris

counties_sf_20 <- counties(year = 2020)

# Shift Alaska, Hawaii, and Puerto Rico, this is another way to shift the geometry
counties_sf_shifted <- shift_geometry(counties_sf_20)


## Step 3: Join the data and shapefile

map_pop_dec <- left_join(counties_sf_shifted, 
                         pop_dec, 
                         by = "GEOID") %>%
    filter(!is.na(NAME.y))              # no data for these territories/islands


## Step 4: Visualization, create a map

ggplot(map_pop_dec) +
    geom_sf(aes(fill = value)) +
    scale_fill_viridis_c(direction = -1,
                         labels = label_comma(accuracy = 1)) +
    labs(title = "County Population Counts from the 2020 Decennial Census",
         caption = "Source: Decennial Census 2020")



# Example 5: Mapping County-Level Poverty Rates in the Mid-Atlantic Region

## Step 1: Data call to the Census API

poverty_county <- get_acs(
    geography = "county",
    variables = "B17001_002",
    state = c("MD", "VA", "PA", "DC", "DE", "WV"),
    year = 2023,
    survey = "acs5",
    show_call = TRUE)

state_counties <- poverty_county$GEOID

## Step 2: Shapefile from tigris

counties_sf_24 <- counties(year = 2023, 
                           cb = TRUE) # cb = generalized shapefile, more details/more resources

counties_sf_24_shifted <- shift_geometry(counties_sf_24)


## Step 3: Join the data and shapefile

map_pov_acs5 <- counties_sf_24_shifted %>%
    filter(GEOID %in% state_counties) %>%        # filter the geoid so it only maps what we have data for
    left_join(poverty_county, by = c("GEOID"))
    

## Step 4: Visualization, create a map

ggplot(map_pov_acs5) +
    geom_sf(aes(fill = estimate)) +
    scale_fill_viridis_c(direction = -1,      # reversed from default
                         option = "magma",
                         labels = label_comma(accuracy = 1)) +  
    labs(
        title = "County-Level Poverty Counts in the Mid-Atlantic Region",
        fill = "People",
        caption = "Source: American Community Survey 5-year Estimates 2023")

# Try mapview for an interactive visualization

mapview((map_pov_acs5 %>% 
            select(c("NAME.y", 
                     "NAMELSAD", 
                     "STATE_NAME",
                     "estimate",
                     "moe")) %>%
            rename('County and State' = NAME.y,
                   County = NAMELSAD,
                   State = STATE_NAME,
                   'Poverty Count Estimate' = estimate,
                   'Poverty Count Margin of Error' = moe)), 
        zcol = "Poverty Count Estimate", 
        layer.name = "Poverty Count Estimate")



# Example 6: Mapping Bachelor's Degree Attainment Across California Census Tracts

## Step 1: Data call to the Census API

edu_tract <- get_acs(
    geography = "tract",
    variables = "B15003_022", # bachelor's degree
    state = "CA",
    year = 2022,
    survey = "acs5",
    show_call = TRUE)


## Step 2: Shapefile from tigris

tracts_sf_24 <- tracts(state = "CA", 
                       year = 2022, 
                       cb = TRUE)


## Step 3: Join the data and shapeFile

map_edu_acs5 <- tracts_sf_24 %>%
    left_join(edu_tract, by = "GEOID")


## Step 4: Visualization, create a map

ggplot(map_edu_acs5) +
    geom_sf(aes(fill = estimate), color = NA) +
    scale_fill_viridis_c(direction = -1,
                         option = "plasma",
                         labels = label_comma(accuracy = 1)) +
    labs(
        title = "Bachelor's Degree Attainment Across California Census Tracts",
        fill = "Estimate",
        caption = "Source: American Community Survey 5-year Estimates 2022")

# Try mapview for an interactive visualization

mapview(map_edu_acs5 %>% 
            select(c("NAME.y", 
                     "NAMELSAD", 
                     "STATE_NAME",
                     "estimate",
                     "moe")) %>%
            rename('Tract and State' = NAME.y,
                   Tract = NAMELSAD,
                   State = STATE_NAME,
                   'Bachelors Degree Attainment Estimate' = estimate,
                   'Bachelors Degree Attainment Margin of Error' = moe), 
        zcol = "Bachelors Degree Attainment Estimate", 
        layer.name = "Bachelors Degree Attainment Estimate")



# Example 7: Mapping Median Household Income with Built-In Geometry

## Step 1: Data call to the Census API

income_state <- get_acs(
    geography = "state",
    variables = "B19013_001",
    year = 2024,
    survey = "acs1",
    geometry = TRUE,             # no need to get the shapefile, we have the geometry
    show_call = TRUE) %>%
    shift_geometry() %>%
    rename(Estimate = estimate)

## Step 2: Visualization, create a map

ggplot(income_state) +
    geom_sf(aes(fill = Estimate)) +
    scale_fill_viridis_c(direction = -1, 
                         option = "cividis",
                         labels = scales::dollar) +
    labs(title = "United States Income by State", 
         caption = "Source: American Community Survey 1-year Estimate 2024")



# Example 8: Calculating and Mapping Poverty Rates by County

## Step 1: Data call to the Census API

poverty_pct <- get_acs(
    geography = "county",
    variables = "B17001_002",     # estimate, Total:!!Income in the past 12 months below poverty level
    summary_var = "B17001_001",   # estimate denominator, Poverty Status in the Past 12 Months by Sex by Age
    year = 2024,
    survey = "acs5",
    geometry = TRUE) %>%
    shift_geometry() %>%    
    mutate(pct_poverty = percent(estimate / summary_est, accuracy = 0.1))

poverty_pct$pct_poverty_num <- as.numeric(sub("%", "", poverty_pct$pct_poverty)) / 100

## Step 2: Visualization, create a map

ggplot(poverty_pct) +
    geom_sf(aes(fill = pct_poverty_num)) +
    scale_fill_viridis_c(direction = -1, 
                         option = "magma",
                         labels = scales::label_percent(accuracy = 1)) +
    labs(title = "US County-Level Percent in Poverty",
         caption = "Source: American Community Survey 5-year Estimates 2024")

# Try mapview for an interactive visualization

mapview(poverty_pct %>%
            select(c("NAME", 
                     "estimate",
                     "moe",
                     "pct_poverty",
                     "pct_poverty_num")) %>%
            rename('State' = NAME,
                   'Poverty Estimate' = estimate,
                   'Poverty Estimate Margin of Error' = moe,
                   'Percent in Poverty' = pct_poverty), 
        zcol = "pct_poverty_num", 
        layer.name = "Percent in Poverty")



# Example 9: Comparing Educational Attainment with Side-by-Side Maps

## Step 1: Data call to the Census API

edu_ny_geo <- get_acs(
    geography = "tract",
    state = "NY",
    variables = c(
        bachelors = "B15003_022",
        masters = "B15003_023"),
    output = "wide",
    year = 2023,
    survey = "acs5",
    geometry = TRUE,
    show_call = TRUE) %>%
    rename(Bachelors = bachelorsE,
           Masters = mastersE)

head(edu_ny_geo)  # view the wide output


## Step 2: Visualization, create a side by side map

p1 = ggplot(edu_ny_geo) +
    geom_sf(aes(fill = Bachelors)) +
    scale_fill_viridis_c(direction = -1,
                         option = "plasma",
                         labels = label_comma(accuracy = 1)) +
    labs(title = "Bachelor's Degrees")

p2 = ggplot(edu_ny_geo) +
    geom_sf(aes(fill = Masters)) +
    scale_fill_viridis_c(direction = -1,
                         option = "plasma",
                         labels = label_comma(accuracy = 1)) +
    labs(title = "Master's Degrees", 
         caption = "Source: American Community Survey 5-year Estimates 2023")

(p1 | p2) + plot_annotation(
    title = "Educational Attainment Across New York Census Tracts")


# Visualization with a log transformation, to bring the colors out

p3 = ggplot(edu_ny_geo) +
    geom_sf(aes(fill = Bachelors)) +
    scale_fill_viridis_c(trans = "log10", 
                         direction = -1,
                         option = "plasma",
                         labels = label_comma(accuracy = 1)) +
    labs(title = "Bachelor's Degrees (Log10)")

p4 = ggplot(edu_ny_geo) +
    geom_sf(aes(fill = Masters)) +
    scale_fill_viridis_c(trans = "log10", 
                         direction = -1,
                         option = "plasma",
                         labels = label_comma(accuracy = 1)) +
    labs(title = "Master's Degrees (Log10)", 
         caption = "Source: American Community Survey 5-year Estimates 2023")

(p3 | p4) + plot_annotation(
    title = "Educational Attainment Across New York Census Tracts (Log10 Scale)")



# Example 10: Mapping Income and Landmarks in Washington, DC

## Step 1: Data call to the Census API

dc_income <- get_acs(
    geography = "tract",
    state = "DC",
    variables = "B19013_001",
    survey = "acs5",
    year = 2024,
    geometry = TRUE,
    show_call = TRUE) %>%
    rename(Estimate = estimate)


## Step 2: Shapefile from tigris

dc_landmarks <- landmarks(state = "DC")


## Step 3: Visualization, create a map with two layers

ggplot() +
    geom_sf(data = dc_income, aes(fill = Estimate, alpha = 0.7)) +
    scale_fill_continuous(labels = label_comma()) +
    geom_sf(data = dc_landmarks, color = "red", size = 1) +
    labs(title = "Median Household Income and Major Landmarks in Washington, DC",
         caption = "Source: American Community Survey 5-year Estimates 2024")
