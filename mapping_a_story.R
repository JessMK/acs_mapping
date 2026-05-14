# Mapping Commute Patterns with ACS Data

# Using geography to reveal commuting structure

# We will demonstrate how ACS data can be transformed into
# meaningful geographic stories using popular R packages.

# PRESENTATION QUESTION:
# "How does geography shape commute times in America?"

# HYPOTHESIS:
# Areas surrounding major metropolitan centers often
# experience longer commute times than urban cores or
# deeply rural areas.

# WHY USE MAPS?
# Traditional charts summarize data.
# Maps reveal spatial patterns and relationships.

# PACKAGES USED:

# tidycensus  -> ACS API access; https://walker-data.com/tidycensus/
# tigris      -> Census shapefiles; https://github.com/walkerke/tigris
# ggplot2     -> static thematic maps
# leaflet     -> interactive web maps

# Get a Census API key here: https://api.census.gov/data/key_signup.html



# 1. LOAD YOUR LIBRARIES

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



# 2. CREATE OUTPUT FOLDER

# Create folder for exported visualizations

if (!dir.exists("mapping_visualizations")) {
    dir.create("mapping_visualizations")
}



# 3. TIGRIS SETTINGS

# Cache shapefiles locally for faster repeated loading

options(tigris_use_cache = TRUE)

# Return sf objects
options(tigris_class = "sf")



# 4. ACS VARIABLES

# ACS table: B08303 = Travel Time to Work

# We will focus on longer commute categories.

acs_vars <- c(
    total_workers   = "B08303_001",
    commute_40_44   = "B08303_010",
    commute_45_59   = "B08303_011",
    commute_60_89   = "B08303_012",
    commute_90_plus = "B08303_013")



# 5. RETRIEVE ACS DATA

# County-level ACS data for the U.S.

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
            (commute_40_44E * 42 +
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



# 6. RETRIEVE SHAPEFILES

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



# 7. JOIN ACS + GEOGRAPHY


county_map <- counties_sf %>%
    left_join(commute_acs, by = "GEOID")



# 8. CREATE A CENSUS COLOR PALETTE

# Census-style blue palette

census_blues <- c(
    "#D5E1EF",  #very light blue tint
    "#A9C3DF",  #light desaturated blue
    "#7DA5CF",  #medium-light blue
    "#4F84BA",  #midtone complementary blue
    "#205493",  #official Census Blue
    "#0E3B6F",  #darkened Census Blue
    "#062644")  #very dark navy anchor



# Now, let's start mapping!

# MAP 1: NATIONAL COUNTY CHOROPLETH

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
         caption = "Source: ACS5 2024 Commute Data") +
    coord_sf(expand = FALSE) +
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
national_map


# Export map
ggsave(
    filename = "mapping_visualizations/national_commute_map.png",
    plot = national_map,
    width = 10,
    height = 6,
    dpi = 300,
    bg = "white")



# MAP 2: WASHINGTON DC METRO ZOOM


# PURPOSE: Explore suburban commute patterns.

# This helps investigate the hypothesis that
# commute times increase outside urban cores.

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


# Export map
ggsave(
    filename = "mapping_visualizations/dc_commute_map.png",
    plot = dc_map,
    width = 8,
    height = 6,
    dpi = 300,
    bg = "white")
