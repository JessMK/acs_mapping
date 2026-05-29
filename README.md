## ACS Mapping Demonstration

This repository contains demo materials, code examples, and resources from a public presentation on connecting to and mapping American Community Survey (ACS) data in R.

You can request a [Census API key here.](https://api.census.gov/data/key_signup.html) This is required for all data calls, learn more [here.](https://www.census.gov/library/video/2026/adrm/requesting-a-census-data-api-key.html)

## Opening this Project

- Download or clone this repository
- Open acs-mapping.Rproj
- Open files from within the RStudio project

## Repository Structure

| Folder | Purpose |
|---|---|
| setup/ | Start here to install your packages and set your API key |
| demos/ | Live presentation and demo scripts for the webinar |
| examples/ | Reusable example scripts to explore ACS data and Census geographies on your own |

## The examples focus on practical, reproducible workflows using:

- [tidycensus package](https://walker-data.com/tidycensus/) and [book Methods, Maps, and Models in R](https://walker-data.com/census-r/)
- [tigris](https://github.com/walkerke/tigris)
- [censusapi](https://www.hrecht.com/censusapi/) and [censusapi github](https://github.com/hrecht/censusapi), for data outside of ACS and Decennial
- packages from the [tidyverse](https://tidyverse.org/) such as dplyr, tidyr
- visualization packages such as ggplot2, [leaflet](https://rstudio.github.io/leaflet/), [mapview](https://r-spatial.github.io/mapview/)
- other formatting packages such as [scales](https://scales.r-lib.org/), [patchwork](https://patchwork.data-imaginist.com/articles/patchwork.html), [sf](https://r-spatial.github.io/sf/)

The goal is to help R users access Census data, create informative maps, and build confidence working with spatial data.

## Topics Covered

- Accessing ACS data with `tidycensus`
- Downloading shapefiles with `tigris`
- Joining data and geometry
- Creating choropleth maps using different geometries
- Styling maps with `ggplot2`
- Exploring demographic and socioeconomic patterns