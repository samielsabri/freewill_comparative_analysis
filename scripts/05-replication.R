#### Preamble ####
# Purpose: Replicate Figures and Tables
# Author: Sami El Sabri, Liban Timir
# Date: 10 February 2023
# Contact: sami.elsabri@mail.utoronto.ca
# License: MIT


#### Workspace setup ####
library(tidyverse)
library(haven)
library(countrycode)
library(ggplot2)

#### Read data ####
penn_world_data <- haven::read_dta("inputs/data/data/aggregates/pwt91.dta")
un_wpp_data <- read_csv("inputs/data/data/aggregates/WPP2019_Period_Indicators_Medium.csv")
ucdp_data <- haven::read_dta("inputs/data/data/aggregates/ucdp_prio/ucdp-prio-acd-201.dta")
# cannot access DHS survey data right now but will add later