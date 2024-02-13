#### Preamble ####
# Purpose: Cleans the raw plane data recorded by two observers..... [...UPDATE THIS...]
# Author: Rohan Alexander [...UPDATE THIS...]
# Date: 6 April 2023 [...UPDATE THIS...]
# Contact: rohan.alexander@utoronto.ca [...UPDATE THIS...]
# License: MIT
# Pre-requisites: [...UPDATE THIS...]
# Any other information needed? [...UPDATE THIS...]

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
