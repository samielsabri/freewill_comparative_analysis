#### Preamble ####
# Purpose: Cleans the raw data provided by Feldman et al. (2017) and by WVS
# Authors: Sami El Sabri, Liban Timir
# Date: 10 February 2023
# Contact: sami.elsabri@mail.utoronto.ca, liban.timir@mail.utoronto.ca
# License: MIT
# Pre-requisites: 01-download_data.R

#### Workspace setup ####
library(tidyverse)
library(dplyr)

#### Clean WVS data ####
wvs_data <- read_csv("inputs/data/study_3/WVS_TimeSeries_4_0.csv")

wvs_data_usa <- wvs_data %>% filter(COUNTRY_ALPHA == "USA") %>% 
  dplyr::select(COUNTRY_ALPHA, S020, S006, S007, A173, C033, C034, F198, G023, C031, X001, X003)
wvs_data <- wvs_data %>% dplyr::select(COUNTRY_ALPHA, S020, S006, S007, A173, C033, C034)

wvs_data <- wvs_data %>% rename(country_code = COUNTRY_ALPHA,
                                year_survey = S020,
                                unified_id = S007,
                                freewill = A173,
                                js = C033,
                                jd = C034
                                )

wvs_data_usa <- wvs_data_usa %>% rename(country_code = COUNTRY_ALPHA,
                                        Age = X003,
                                        Sex = X001,
                                         year_survey = S020,
                                         unified_id = S007,
                                         freewill = A173,
                                         job_satisfaction = C033,
                                         job_decision = C034,
                                         job_pride = C031,
                                         fate = F198,
                                         autonomy = G023
                                        )


country_codes <- c("ARG", "BRA", "CHL", "CHN", "CZE", "IND", "JPN", "MEX", "NGA",
                   "POL", "RUS", "SVK", "ZAF", "KOR", "ESP", "CHE", "USA")

wvs_filtered_replication <- wvs_data %>% filter(country_code %in% country_codes) %>% filter(year_survey <= 2008) %>%
  filter(freewill > 0)

wvs_filtered <- wvs_data %>% filter(country_code %in% country_codes) %>%
  filter(freewill > 0)


wvs_data_usa[wvs_data_usa < 0] <- NA

wvs_data_usa <- wvs_data_usa %>% mutate(across(c("fate"), ~11 - .)) %>% mutate(across(c("job_pride"), ~4 - .))

#### Save WVS data ####
write_csv(wvs_filtered, 'outputs/data/wvs_filtered.csv')
write_csv(wvs_filtered_replication, 'inputs/data/study_3/wvs_filtered.csv')
write_csv(wvs_data_usa, 'outputs/data/wvs_data_usa.csv')

## Clean Study 2 data ##
satisfaction_data_usa <- read_csv("inputs/data/study_2/FW satisfaction-Study 2-data.csv")
satisfaction_data_usa_rel <- satisfaction_data_usa %>% dplyr::select(age, gender, "jobsat1", "jobsat2", "FWDfwagency", "jobaut",
                                                                    "jobaut2", "locus", "ess_kind", "selfest", "selfeff", "selfcontrol")

satisfaction_data_usa_rel <- satisfaction_data_usa_rel %>% rename("Age" = "age", 
                                                                  "Sex" = "gender",
                                                                  "Job Satisfaction (T1)" = "jobsat1", 
                                                                  "Job Satisfaction (T2)" = "jobsat2",
                                                                  "Belief in Free Will (T1)" ="FWDfwagency",
                                                                  "Job Autonomy (T1)" = "jobaut", 
                                                                  "Job Autonomy (T2)" ="jobaut2",
                                                                  "Locus of Control" = "locus",
                                                                  "Implicit Beliefs" = "ess_kind",
                                                                  "Self-Esteem" = "selfest",
                                                                  "Self-Efficacy" ="selfeff", 
                                                                  "Self-Control" = "selfcontrol")

satisfaction_data_usa_rel$age_group <- cut(satisfaction_data_usa_rel$Age,
                    breaks = c(-Inf, 18, 30, 40, 50, 60, Inf),
                    labels = c("Under 18", "18-30", "31-40", "41-50", "51-60", "Over 60"),
                    right = FALSE)



write_csv(satisfaction_data_usa_rel, 'outputs/data/satisfaction_data_usa_rel.csv')


