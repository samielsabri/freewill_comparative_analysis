#### Preamble ####
# Purpose: Cleans the raw data provided by Feldman et al. (2017) and by WVS
# Authors: Sami El Sabri, Liban Timir
# Date: 10 February 2023
# Contact: sami.elsabri@mail.utoronto.ca
# License: MIT
# Pre-requisites: 01-download_data.R

#### Workspace setup ####
library(tidyverse)

#### Clean data ####
wvs_data <- read_csv("inputs/data/study_3/WVS_TimeSeries_4_0.csv")
wvs_data <- wvs_data %>% select(COUNTRY_ALPHA, S020, S006, S007, A173, C033, C034)

wvs_data <- wvs_data %>% rename(country_code = COUNTRY_ALPHA,
                                year_survey = S020,
                                unified_id = S007,
                                freewill = A173,
                                js = C033,
                                jd = C034
                                )

country_codes <- c("ARG", "BRA", "CHL", "CHN", "CZE", "IND", "JPN", "MEX", "NGA",
                   "POL", "RUS", "SVK", "ZAF", "KOR", "ESP", "CHE", "USA")

wvs_filtered <- wvs_data %>% filter(country_code %in% country_codes) %>% filter(year_survey <= 2008) %>%
  filter(freewill > 0)

#### Save data ####
write_csv(wvs_filtered, 'inputs/data/study_3/wvs_filtered.csv') # because original file is way too big
