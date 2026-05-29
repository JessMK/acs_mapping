# Mapping Commute Patterns with ACS Data
# Using data and geography to reveal commuting structure

# We will demonstrate how ACS data can be transformed into
# meaningful geographic stories using popular R packages

# WHY USE MAPS?
# Traditional charts summarize data
# Maps reveal spatial patterns and relationships

# CORE PACKAGES USED:

# tidycensus  -> ACS API access; https://walker-data.com/tidycensus/
# tigris      -> Census shapefiles; https://github.com/walkerke/tigris
# ggplot2     -> static thematic maps
# leaflet     -> interactive web maps

# Start with the 00_setup.R file to install necessary packages and Census API key

# 1. Load your Libraries

# Census data
library(tidycensus)
# Census shapefiles
library(tigris)
# data wrangling
library(tidyverse)
# spatial data support
library(sf)
# static mapping
library(ggplot2)
# interactive mapping
library(leaflet)
# formatting helpers
library(scales)

# disable scientific notation
options(scipen = 999)

# 2. Create a visualization output folder

# Create folder for exported visualizations, optional

if (!dir.exists("mapping_visualizations")) {
    dir.create("mapping_visualizations")
}


# 3. TIGRIS settings

# Cache shapefiles locally for faster repeated loading, pay attention to space

options(tigris_use_cache = TRUE)

# Return sf objects
options(tigris_class = "sf")


# 4. ACS Variables

# ACS table: B08303 = Travel Time to Work
# https://data.census.gov/table?q=B08303

# We will focus on longer commute categories.
# Universe: Workers 16 years and over who did not work from home

acs_vars <- c(
    total_workers   = "B08303_001",
    commute_30_34   = "B08303_008",
    commute_35_39   = "B08303_009",
    commute_40_44   = "B08303_010",
    commute_45_59   = "B08303_011",
    commute_60_89   = "B08303_012",
    commute_90_plus = "B08303_013")


# 5. Retrieve ACS data

# County-level ACS commute data for the U.S.

commute_acs <- get_acs(
    geography = "county",
    variables = acs_vars,
    year = 2024,
    survey = "acs5",      # acs5 is the default
    output = "wide",      # Wide format will allow for ease of visualization
    show_call = TRUE) %>%
    mutate(
        # COMMUTE INTENSITY INDEX: Approximate weighted commute burden score, 
        # only to be used for demonstration purposes.
        # Larger values indicate counties with more workers
        # experiencing long commute times.
        commute_index =
            (commute_30_34E * 22 +
             commute_35_39E * 32 +   
             commute_40_44E * 42 +
             commute_45_59E * 52 +
             commute_60_89E * 75 +
             commute_90_plusE * 100) / total_workersE)

# Place-level ACS data for the U.S. Population

pop_data <- get_acs(
    geography = "place",
    variables = "B01003_001",  # Total population
    year = 2024,
    survey = "acs5",           # acs5 is the default
    show_call = TRUE) %>%
    select(GEOID, population = estimate)


# 6. Retrieve Shapefiles

# U.S. counties, shifted geometry

counties_sf <- counties(
    cb = TRUE,
    year = 2024) %>%
    filter(STUSPS %in% c("AK", "HI", "PR", state.abb)) %>%
    shift_geometry()  # used to reposition & rescale Alaska, Hawaii, and Puerto Rico


# U.S. states, shifted geometry

states_sf <- states(
    cb = TRUE,
    year = 2024) %>%
    filter(STUSPS %in% c("AK", "HI", "PR", state.abb)) %>%
    shift_geometry()


# U.S places

places_sf <- places(
    cb = TRUE, 
    year = 2024) %>%
    filter(STUSPS %in% c("AK", "HI", "PR", state.abb)) %>%
    shift_geometry() %>% 
    mutate(area_sqkm = as.numeric(st_area(geometry)) / 1e6) %>%
    mutate(STUSPS_FIPS = substr(GEOID, 1, 2))  # first two digits of GEOID = state FIPS


# U.S Capitals

state_caps <- tibble::tribble(
    ~state, ~capital,
    "AL", "Montgomery",
    "AK", "Juneau",
    "AZ", "Phoenix",
    "AR", "Little Rock",
    "CA", "Sacramento",
    "CO", "Denver",
    "CT", "Hartford",
    "DE", "Dover",
    "FL", "Tallahassee",
    "GA", "Atlanta",
    "HI", "Honolulu",  # Note, won't be mapped, this is not a Census Place
    "ID", "Boise City",
    "IL", "Springfield",
    "IN", "Indianapolis city (balance)",
    "IA", "Des Moines",
    "KS", "Topeka",
    "KY", "Frankfort",
    "LA", "Baton Rouge",
    "ME", "Augusta",
    "MD", "Annapolis",
    "MA", "Boston",
    "MI", "Lansing",
    "MN", "St. Paul",
    "MS", "Jackson",
    "MO", "Jefferson City",
    "MT", "Helena",
    "NE", "Lincoln",
    "NV", "Carson City",
    "NH", "Concord",
    "NJ", "Trenton",
    "NM", "Santa Fe",
    "NY", "Albany",
    "NC", "Raleigh",
    "ND", "Bismarck",
    "OH", "Columbus",
    "OK", "Oklahoma City",
    "OR", "Salem",
    "PA", "Harrisburg",
    "RI", "Providence",
    "SC", "Columbia",
    "SD", "Pierre",
    "TN", "Nashville-Davidson metropolitan government (balance)",
    "TX", "Austin",
    "UT", "Salt Lake City",
    "VT", "Montpelier",
    "VA", "Richmond",
    "WA", "Olympia",
    "WV", "Charleston",
    "WI", "Madison",
    "WY", "Cheyenne",
    "DC", "Washington")

state_capitals_sf <- places_sf %>%
    inner_join(state_caps, by = c("STUSPS" = "state", "NAME" = "capital"))


# U.S city centers

city_points <- places_sf %>% 
    st_centroid() %>% 
    filter(PLACEFP != "99999") %>%  # removes non-places
    left_join(pop_data, by = "GEOID")

major_cities <- city_points |> 
    filter(STUSPS %in% state.abb | STUSPS == "DC") |> 
    filter(AWATER < ALAND) %>%       # remove water-only features
    mutate(density = population / area_sqkm) %>%
    filter(density > 3000)


# 7. Join ACS data + Geography

county_map <- counties_sf %>%
    left_join(commute_acs, by = "GEOID")


# 8. Create a Census Color Palette

# Census-style blue palette

census_blues <- c(
    "#D5E1EF",  #very light blue tint
    "#A9C3DF",  #light desaturated blue
    "#7DA5CF",  #medium-light blue
    "#4F84BA",  #midtone complementary blue
    "#205493",  #official Census Blue
    "#0E3B6F",  #darkened Census Blue
    "#062644")  #very dark navy anchor


# Now, lets start mapping!

# MAP 1: National County Choropleth

# Lets use a map to reveal national commute patterns.

national_map <- ggplot(county_map) +
    geom_sf(aes(fill = commute_index), 
            color = NA) +
    geom_sf(data = state_capitals_sf, 
            color = "darkred",
            shape = 8,
            size = 1,
            alpha = 0.7) +
    geom_sf(data = major_cities, 
            color = "darkorange",
            shape = 18,
            size = 1,
            alpha = 0.7) +
    scale_fill_gradientn(colors = census_blues,
                         name = "Commute Index",
                         labels = scales::label_number(accuracy = 1)) +
    labs(title = "Commute Time Patterns Across U.S. Counties",
         subtitle = "Red = State Capitals | Orange = Major Cities",
         caption = "Source: ACS5 2024 Commute Data") +
    coord_sf(expand = FALSE) +
    theme_void() +
    theme(plot.title = element_text(hjust = 0.5, face = "bold", margin = margin(b = 5)),
          plot.title.position = "panel",
          plot.subtitle = element_text(hjust = 0.5, margin = margin(b = 4)),
          legend.position = "bottom",
          legend.direction = "horizontal",
          legend.title = element_text(size = 9, face = "bold"),
          legend.text = element_text(size = 8),
          plot.margin = margin(t = 5, r = 5, b = 5, l = 5)) +
    guides(fill = guide_colorbar(title.position = "top", 
                                 barwidth = 14,
                                 barheight = 0.6))

# Display map
national_map

# Export map, optional
ggsave(
    filename = "mapping_visualizations/national_commute_map.png",
    plot = national_map,
    width = 10,
    height = 6,
    dpi = 300,
    bg = "white")


# MAP 2: Washington DC Metro Area Commute

# Lets use a map to explore suburban commute patterns.

dc_counties <- county_map %>%
    filter(STATEFP %in% c("11", # DC
                          "24", # Maryland
                          "51", # Virginia
                          "10", # Delaware
                          "54", # West Virginia
                          "42")) # Pennsylvania    

dc_map <- ggplot(dc_counties) +
    geom_sf(aes(fill = commute_index),
            color = "white",
            linewidth = 0.2) +
    scale_fill_gradientn(colors = census_blues,
                         name = "Commute Index",
                         labels = scales::label_number(accuracy = 1)) +
    coord_sf(expand = FALSE) +
    labs(title = "Commute Patterns Around Washington, DC",
         caption = "Source: ACS5 2024 Commute Data") +
    theme_void() +
    theme(plot.title = element_text(hjust = 0.5, face = "bold", margin = margin(b = 5)),
          plot.title.position = "panel",
          legend.position = "bottom",
          legend.direction = "horizontal",
          legend.title = element_text(size = 9, face = "bold"),
          legend.text = element_text(size = 8),
          plot.margin = margin(t = 5, r = 5, b = 5, l = 5)) +
    guides(fill = guide_colorbar(title.position = "top", 
                                 barwidth = 14,
                                 barheight = 0.6))


# Display map
dc_map


# Export map, optional
ggsave(
    filename = "mapping_visualizations/dc_commute_map.png",
    plot = dc_map,
    width = 8,
    height = 6,
    dpi = 300,
    bg = "white")


# MAP 3: Weighted Average Commute Time by State

# Lets use a map to see which states have the longest commute times?

# Get state level commute table

commute_time <- get_acs(geography = "state", 
                        table = "B08303", 
                        year = 2024, 
                        survey = "acs5",
                        output = "wide",
                        show_call = TRUE)

colnames(commute_time)


# Define midpoints for each commute variable

midpoints <- c(
    "B08303_002E" = 2.5,
    "B08303_003E" = 7,
    "B08303_004E" = 12,
    "B08303_005E" = 17,
    "B08303_006E" = 22,
    "B08303_007E" = 27,
    "B08303_008E" = 32,
    "B08303_009E" = 37,
    "B08303_010E" = 42,
    "B08303_011E" = 52.5,
    "B08303_012E" = 75,
    "B08303_013E" = 95)


# Compute weighted mean commute time

commute_weighted <- commute_time %>%
    rowwise() %>%
    mutate(
        avg_commute = sum(c_across(names(midpoints)) * midpoints) /
            B08303_001E) %>%
    ungroup() %>%
    select(GEOID, NAME, avg_commute)


# Get state level shapefile and shift geometry

states_sf <- states(cb = TRUE, 
                    year = 2024) %>% 
    shift_geometry()

# Join our data and shapefile

commute_map <- states_sf %>% 
    left_join(commute_weighted, by = "GEOID")

# Create the commute map
# ACS estimates are already aggregated for us. 
# We are mapping the estimated mean commute time directly from Census data.

state_map <- ggplot(commute_map) +
    geom_sf(aes(fill = avg_commute),
            color = "white",
            linewidth = 0.2) +
    scale_fill_gradientn(colors = census_blues,
                         name = "Total Minutes") +
    labs(title = "Weighted Commute Time by State",
        subtitle = "American Community Survey 5-Year Estimates (2024)",
        caption = "Source: U.S. Census Bureau ACS") +
    coord_sf(expand = FALSE) +
    theme_void() +
    theme(plot.title = element_text(hjust = 0.5, face = "bold", margin = margin(b = 5)),
          plot.title.position = "panel",
          plot.subtitle = element_text(hjust = 0.5, margin = margin(b = 4)),
          legend.position = "bottom",
          legend.direction = "horizontal",
          legend.title = element_text(size = 9, face = "bold"),
          legend.text = element_text(size = 8),
          plot.margin = margin(t = 5, r = 5, b = 5, l = 5)) +
    guides(fill = guide_colorbar(title.position = "top", 
                                 barwidth = 14,
                                 barheight = 0.6))


# Display map
state_map


# Export map, optional
ggsave(
    filename = "mapping_visualizations/state_commute_map.png",
    plot = state_map,
    width = 8,
    height = 6,
    dpi = 300,
    bg = "white")
