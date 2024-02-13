#### Preamble ####
# Purpose: Replicate Table 4 of Feldman et al. (2017)
# Author: Sami El Sabri, Liban Timir
# Date: 10 February 2023
# Contact: sami.elsabri@mail.utoronto.ca
# License: MIT


#### Workspace setup ####
library(tidyverse)
library(countrycode)
library(ggplot2)
library(knitr)

#### Read data ####
# wvs_data <- read_csv("inputs/data/study_3/WVS_TimeSeries_4_0.csv")

### Clean data

# wvs_data <- wvs_data %>% select(COUNTRY_ALPHA, S020, S006, S007, A173, C033, C034)
# 
# wvs_data <- wvs_data %>% rename(country_code = COUNTRY_ALPHA,
#                                 year_survey = S020,
#                                 unified_id = S007,
#                                 freewill = A173,
#                                 js = C033,
#                                 jd = C034
#                                 )
# 
# country_codes <- c("ARG", "BRA", "CHL", "CHN", "CZE", "IND", "JPN", "MEX", "NGA", 
#                    "POL", "RUS", "SVK", "ZAF", "KOR", "ESP", "CHE", "USA")
# 
# wvs_filtered <- wvs_data %>% filter(country_code %in% country_codes) %>% filter(year_survey <= 2008) %>% 
#   filter(freewill > 0)

write_csv(wvs_filtered, 'inputs/data/study_3/wvs_filtered.csv') # because original file is way too big

## Read smaller data file
wvs_filtered <- read_csv("inputs/data/study_3/wvs_filtered.csv")

wvs_summary_table <- wvs_filtered %>% group_by(country_code) %>% 
  summarize("FW Mean"=round(mean(freewill),2), n=n())

wvs_filtered_2 <- wvs_filtered %>% filter(js > 0)

correlations <- wvs_filtered_2 %>%
  group_by(country_code) %>%
  do(correlation = cor(.$freewill, .$js, use = "complete.obs"))

correlations <- wvs_filtered_2 %>%
  group_by(country_code) %>%
  summarize(correlation = list(cor(freewill, js, use = "complete.obs"))) %>%
  ungroup() %>%
  mutate(correlation = map_dbl(correlation, ~ round(.x, 2)))

final_table <- left_join(wvs_summary_table, correlations, by = "country_code")
final_table <- final_table %>% mutate("Country Name" = countrycode(country_code, "iso3c", "country.name"))
final_table <- final_table[c(5, 2, 4, 3)]
final_table <- final_table %>% rename("Correlation" = correlation)
final_table <- final_table %>% filter(`Country Name` != 'United States')
