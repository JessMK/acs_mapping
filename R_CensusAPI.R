# Install our packages, if necessary

#install.packages(c("tidycensus",   # https://walker-data.com/tidycensus/; https://walker-data.com/census-r/
#                   "censusapi",    # https://www.hrecht.com/censusapi/; https://github.com/hrecht/censusapi
#                   "tigris",       # https://github.com/walkerke/tigris
#                   "dplyr",        # https://dplyr.tidyverse.org/
#                   "tidyr",        # https://tidyr.tidyverse.org/
#                   "ggplot2",      # https://ggplot2.tidyverse.org/
#                   "mapview",      # https://r-spatial.github.io/mapview/
#                   "patchwork"))   # https://patchwork.data-imaginist.com/articles/patchwork.html

# geography functions/options: https://walker-data.com/census-r/an-introduction-to-tidycensus.html#geography-and-variables-in-tidycensus


# For Census Data

library(tidycensus) # ACS, Decennial 
library(censusapi) # everything else  

# For Census ShapeFiles

library(tigris)

options(tigris_use_cache = TRUE)   # to save your shapefiles for ease of recall

# For working with the data and visualization

library(dplyr)
library(tidyr)
library(ggplot2)

# For interactive maps

library(mapview)

# For map/visual formatting and composition

library(patchwork)


# disable scientific notation

options(scipen = 999)

# Census API Key is required

#census_api_key("INSERT YOUR KEY HERE", 
#               install = TRUE, 
#               overwrite = TRUE)
#

# Lets take a look at the available datasets

apis <- listCensusApis()   # Get general information about available datasets

View(apis)


# Mental Model for working with the Census API

# Every tidycensus call is a structured API query that returns a data frame.

# Every Census API call is:
##   a dataset + a geography + variables + filters = a table

# Every Census map is: 
##   a data call + shape file + join = visualization

# We’ll repeat this pattern across multiple datasets.



# Example 1: ACS Population (States)
    
## Step 1: Data call to the Census API

pop_acs <- get_acs(
    geography = "state",                # http://api.census.gov/data/2024/acs/acs1/geography.json
    variables = c("B01001_001",         # http://api.census.gov/data/2024/acs/acs1/variables.json
                  "B01001_003E",
                  "B01001_005E"),
    year = 2024, 
    survey= "acs1",
    show_call = TRUE)                   # show the URL 


## Step 2: Get your ShapeFile from tigris

states_sf <- states(year = 2024)


## Step 3: Join the data and ShapeFile

map_pop_acs <- left_join(states_sf, 
                         pop_acs, 
                         by = "GEOID")


## Step 4: Visualization, create a map

ggplot(map_pop_acs) +
    geom_sf(aes(fill = estimate)) +
    scale_fill_viridis_c(direction = -1) +
    labs(title = "United State Population",
         caption = "Source: ACS 1-year, 2024")

# note that this is the standard view, but this is not the Census standard view



# Example 2: ACS Population (States)

# a second example with the same data, wide for mapview

pop_acs_wide <- get_acs(
    geography = "state",                # http://api.census.gov/data/2024/acs/acs1/geography.json
    variables = c("B01001_001",         # http://api.census.gov/data/2024/acs/acs1/variables.json
                  "B01001_003E",
                  "B01001_005E"),
    year = 2024, 
    survey= "acs1",
    output = "wide",
    show_call = TRUE)  

# join your shapefile and your data

map_pop_acs_wide <- left_join(states_sf, 
                              pop_acs_wide, 
                              by = "GEOID")

# visualize using mapview

mapview((map_pop_acs_wide %>% 
            select(c("NAME.y", 
                "REGION",
                "B01001_001E",         # http://api.census.gov/data/2024/acs/acs1/variables.json
                "B01001_003E",
                "B01001_005E")) %>%
            mutate(REGION = case_when(
                REGION == "1" ~ "Northeast",
                REGION == "2" ~ "Midwest", 
                REGION == "3" ~ "South",
                REGION == "4" ~ "West"))), zcol = "REGION")



## Try this same example with a shifted geometry, which is better for Census mapping

## Step 1: Data call to the Census API with geometry included, and shift it to a Census standard

pop_acs_geo <- get_acs(
    geography = "state",
    variables = "B01001_001",
    geometry = TRUE,   # bring the geometry in during the data call, tidycensus possible
    year = 2024,      
    survey= "acs1",
    show_call = TRUE) %>% 
    shift_geometry()  # shift_geometry gives us the census standard view


## Step 2: Visualization, we dont need to get the shapefile since we have geometry

ggplot(pop_acs_geo) +
    geom_sf(aes(fill = estimate)) +
    scale_fill_viridis_c(direction = -1) +
    labs(title = "United States Population",
         caption = "Source: ACS 1-year, 2024")



# Example 3: Decennial Census (Counties)
    
## Population by county (2020)
    
## Step 1: Data call to the Census API

pop_dec <- get_decennial(
    geography = "county",
    variables = "P1_001N",
    year = 2020,
    show_call = TRUE)


## Step 2: ShapeFile from tigris

counties_sf_20 <- counties(year = 2020)

# Shift Alaska, Hawaii, and Puerto Rico, another way to shift the geometry
counties_sf_shifted <- shift_geometry(counties_sf_20)


## Step 3: Join the data and ShapeFile

map_pop_dec <- left_join(counties_sf_shifted, 
                         pop_dec, 
                         by = "GEOID") %>%
    filter(!is.na(NAME.y))              # no data for these territories/islands


## Step 4: Visualization, create a map

ggplot(map_pop_dec) +
    geom_sf(aes(fill = value)) +
    scale_fill_viridis_c(direction = -1) +
    labs(title = "US County-Level Population",
         caption = "Source: Decennial Census, 2020")



# Example 4: ACS 5, poverty by county

## Step 1: Data call to the Census API

poverty_county <- get_acs(
    geography = "county",
    variables = "B17001_002",
    state = c("MD", "VA", "PA", "DC", "DE", "WV"),
    year = 2023,
    survey = "acs5",
    show_call = TRUE)

state_counties <- poverty_county$GEOID

## Step 2: ShapeFile from tigris

counties_sf_24 <- counties(year = 2023, 
                           cb = TRUE) # cb = generalized shapefile, more details/more resources

counties_sf_24_shifted <- shift_geometry(counties_sf_24)


## Step 3: Join the data and ShapeFile

map_pov_acs5 <- counties_sf_24_shifted %>%
    filter(GEOID %in% state_counties) %>%        # filter the geoid so it only maps what we have data for
    left_join(poverty_county, by = c("GEOID"))
    

## Step 4: Visualization, create a map

ggplot(map_pov_acs5) +
    geom_sf(aes(fill = estimate)) +
    scale_fill_viridis_c(direction = -1) +  # reversed from default
    labs(
        title = "US County-Level Population Below Poverty Line",
        fill = "People",
        caption = "Source: ACS 5-year, 2023")

# or mapview

mapview(map_pov_acs5, zcol = "estimate")



# Example 5: ACS 5, education by Census tract for a single state

## Step 1: Data call to the Census API

edu_tract <- get_acs(
    geography = "tract",
    variables = "B15003_022", # bachelor's degree
    state = "CA",
    year = 2022,
    survey = "acs5",
    show_call = TRUE)


## Step 2: ShapeFile from tigris

tracts_sf_24 <- tracts(state = "CA", 
                       year = 2022, 
                       cb = TRUE)


## Step 3: Join the data and ShapeFile

map_edu_acs5 <- tracts_sf_24 %>%
    left_join(edu_tract, by = "GEOID")


## Step 4: Visualization, create a map

ggplot(map_edu_acs5) +
    geom_sf(aes(fill = estimate), color = NA) +
    scale_fill_viridis_c(direction = -1) +
    labs(
        title = "Bachelor's Degrees by Census Tract",
        fill = "Count",
        caption = "Source: ACS 5-year, 2022")

# or mapview

mapview(map_edu_acs5, zcol = "estimate")



# Example 6: ACS1, income by state, pulling geometry directly

## Step 1: Data call to the Census API

income_state <- get_acs(
    geography = "state",
    variables = "B19013_001",
    year = 2024,
    survey = "acs1",
    geometry = TRUE,             # no need to get the shapefile, we have the geometry
    show_call = TRUE) %>%
    shift_geometry()

## Step 2: Visualization, create a map

ggplot(income_state) +
    geom_sf(aes(fill = estimate)) +
    scale_fill_viridis_c(direction = -1, labels = scales::dollar) +
    labs(title = "United States Income by State", 
         subtitle = "Geometry pulled directly",
         caption = "Source: ACS 1-year, 2024")



# Example 7: ACS5, poverty rates by county

## Step 1: Data call to the Census API

poverty_pct <- get_acs(
    geography = "county",
    variables = "B17001_002",     # estimate, Total:!!Income in the past 12 months below poverty level
    summary_var = "B17001_001",   # estimate denominator, Poverty Status in the Past 12 Months by Sex by Age
    year = 2024,
    survey = "acs5",
    geometry = TRUE) %>%
    shift_geometry() %>%    
    mutate(pct_poverty = estimate / summary_est * 100)

## Step 2: Visualization, create a map

ggplot(poverty_pct) +
    geom_sf(aes(fill = pct_poverty)) +
    scale_fill_viridis_c(direction = -1, label = scales::label_percent(1.0)) +
    labs(title = "US County-Level Percent in Poverty",
         caption = "Source: ACS 5-year, 2024")

# or mapview

mapview(poverty_pct, zcol = "pct_poverty")



# Example 8: ACS5, degrees by tract, multiple variables, wide format

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
    show_call = TRUE)

head(edu_ny_geo)  # view the wide output


## Step 2: Visualization, create a side by side map

p1 = ggplot(edu_ny_geo) +
    geom_sf(aes(fill = bachelorsE)) +
    scale_fill_viridis_c(direction = -1) +
    labs(title = "Bachelor's Degrees", 
         subtitle = "wide output",
         caption = "Source: ACS 5-year, 2023")

p2 = ggplot(edu_ny_geo) +
    geom_sf(aes(fill = mastersE)) +
    scale_fill_viridis_c(direction = -1) +
    labs(title = "Master's Degrees", 
         subtitle = "wide output",
         caption = "Source: ACS 5-year, 2023")

p1 | p2


# Visualization with a log transformation, to bring the colors out

p3 = ggplot(edu_ny_geo) +
    geom_sf(aes(fill = bachelorsE)) +
    scale_fill_viridis_c(trans = "log10", direction = -1) +
    labs(title = "Bachelor's Degrees", 
         subtitle = "wide output",
         caption = "Source: ACS 5-year, 2023")

p4 = ggplot(edu_ny_geo) +
    geom_sf(aes(fill = mastersE)) +
    scale_fill_viridis_c(trans = "log10", direction = -1) +
    labs(title = "Master's Degrees", 
         subtitle = "wide output",
         caption = "Source: ACS 5-year, 2023")

p3 | p4



# Example 9: DC Income and Landmarks

## Step 1: Data call to the Census API

dc_income <- get_acs(
    geography = "tract",
    state = "DC",
    variables = "B19013_001",
    survey = "acs5",
    year = 2024,
    geometry = TRUE,
    show_call = TRUE)


## Step 2: ShapeFile from tigris

dc_landmarks <- landmarks(state = "DC")


## Step 3: Visualization, create a map with two layers

ggplot() +
    geom_sf(data = dc_income, aes(fill = estimate), alpha = 0.7) +
    geom_sf(data = dc_landmarks, color = "red", size = 1) +
    labs(title = "Income + Landmarks Overlay in Washington DC",
         caption = "Source: ACS 5-year, 2024")
