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
