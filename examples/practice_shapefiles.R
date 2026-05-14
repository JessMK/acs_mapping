# Learn about Census Shapefiles for mapping

# Load necessary libraries

pkgs_shapefiles <- c("tigris", "sf", "tidyverse", "patchwork")

invisible(lapply(pkgs_shapefiles, library, character.only = TRUE))

# This will save downloading resources with ShapeFile you use regularly

#options(tigris_use_cache = TRUE)


# Exercise 1: Download State Boundaries
# Goal: Learn how to download state-level shapefiles.

states_sf <- states(cb = TRUE) %>% shift_geometry()

plot(st_geometry(states_sf))


# Exercise 2: County Boundaries for One State
# Goal: Filter by state and explore sub-state geographies.

ca_counties <- counties(state = "CA", cb = TRUE)

ggplot(ca_counties) + 
    geom_sf() + 
    ggtitle("Counties of California")

me_counties <- counties(state = "ME", cb = TRUE)

ggplot(me_counties) + 
    geom_sf() + 
    ggtitle("Counties of Maine")


# Exercise 3: Census Tracts in an Urban Area
# Goal: Examine tract-level detail in a metropolitan area.

pg_tracts <- tracts(state = "MD", 
                    county = "Prince George", 
                    cb = TRUE)

ggplot(pg_tracts) + 
    geom_sf() + 
    ggtitle("Census Tracts in Prince Georges County")

calvert_tracts <- tracts(state = "MD", 
                    county = "Calvert", 
                    cb = TRUE)

ggplot(calvert_tracts) + 
    geom_sf() + 
    ggtitle("Census Tracts in Calvert County")


# Exercise 4: Block Groups in a Small City
# Goal: Visualize very fine-grained geographic units.

wayne_bgs <- block_groups(state = "MI", 
                          county = "Wayne", 
                          cb = TRUE)

ggplot(wayne_bgs) + 
    geom_sf() + 
    ggtitle("Block Groups in Wayne County")

texas_bgs <- block_groups(state = "TX", 
                          county = "Bexar", 
                          cb = TRUE)

ggplot(texas_bgs) + 
    geom_sf() + 
    ggtitle("Block Groups in Bexar County")


#️ Exercise 5: Zip Code Tabulation Areas (ZCTAs)
# Goal: Work with postal-related boundaries.

zctas <- zctas(cb = FALSE)

ggplot(zctas) + 
    geom_sf() + 
    ggtitle("ZIP Code Tabulation Areas")


#️ Exercise 6: Places (Cities & Towns)
# Goal: Connect municipal-level shapefiles to demographic data.

ny_places <- places(state = "NY", cb = TRUE)

ggplot(ny_places) + 
    geom_sf() + 
    ggtitle("Places in New York State")


# Exercise 7: Compare All Geography Levels for One County
# Goal: See how tract, block group, and ZCTA boundaries overlay in one region.

# Get multiple geographies for Anne Arundel County, Maryland
tracts_md <- tracts(state = "MD", 
                    county = "Anne Arundel", 
                    cb = TRUE)

bgs_md <- block_groups(state = "MD", 
                       county = "Anne Arundel", 
                       cb = TRUE)

zctas_md <- zctas(year = 2020) %>% 
    st_filter(tracts_md, .predicate = st_intersects)


p1 <- ggplot(tracts_md) + 
    geom_sf() + 
    ggtitle("AACO Tracts")

p2 <- ggplot(bgs_md) + 
    geom_sf() + 
    ggtitle("AACO Block Groups")

p3 <- ggplot(zctas_md) + 
    geom_sf() + 
    ggtitle("AACO ZCTAs")

p1 + p2 + p3

p1 / p2 / p3

p1 + p2 / p3


# Exercise 8: Join data with shapefiles for mapping
# - Load shapefile from tigris.
# - Extract GEOID values.
# - Create synthetic data with random or patterned variables.
# - Join synthetic data back to the shapefile for mapping or analysis.

# Step 1. Load the shapefile for a selected geography
# Replace with your desired geography and location (see options below)

geography_sf <- counties(state = "MD", cb = TRUE)  # could be states(), tracts(), block_groups(), etc.

# Step 2. Extract GEOIDs

geoids <- geography_sf %>%
    st_drop_geometry() %>%
    select(GEOID)

# Step 3. Create synthetic data

set.seed(123)  # for reproducibility

synthetic_data <- geoids %>%
    mutate(
        synthetic_age = runif(n(), min = 0, max = 100),
        category = sample(c("A", "B", "C", "D"), size = n(), replace = TRUE),
        population_size = sample(500:50000, size = n(), replace = TRUE)
    )

# Step 4. Join synthetic data to the shapefile

geography_with_data <- geography_sf %>%
    left_join(synthetic_data, by = "GEOID")

# Step 5. Visualize it

ggplot(geography_with_data) +
    geom_sf(aes(fill = population_size)) +
    scale_fill_viridis_c() +
    theme_minimal() +
    labs(title = "Synthetic MD Population Size by GEOID",
         fill = "Pop Size")


# To Use with Any tigris Geography in Step 1

# States
geography_state <- states(cb = TRUE)

# Counties in Texas
geography_county <- counties(state = "TX", cb = TRUE)

# Tracts in Miami-Dade, FL
geography_tracts <- tracts(state = "FL", county = "Miami-Dade", cb = TRUE)

# Block Groups in Baltimore City
geography_blocks <- block_groups(state = "MD", county = "Baltimore city", cb = TRUE)

# ZCTAs (note: no state filter here)
geography_zctas <- zctas(cb = TRUE)

# Places in Illinois
geography_places <- places(state = "IL", cb = TRUE)

# School districts
geography_school <- school_districts(state = "MD", cb = TRUE)
