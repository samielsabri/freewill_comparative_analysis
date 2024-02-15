#### Preamble ####
# Purpose: Simulates the Feldman et al. (2017) and WVS data
# Author: Sami El Sabri, Liban Timir
# Date: 15 February 2024
# Contact: sami.elsabri@mail.utoronto.ca, liban.timir@mail.utoronto.ca
# License: MIT


#### Workspace setup ####
library(tidyverse)
library(dplyr)
library(lubridate)

#### Simulate data ####
set.seed(555) 

num_rows <- 100  

ids <- 1:num_rows

# Simulating free will and job satisfaction scores at two time points
# Assuming free will is measured on a scale from 1 to 6, 
# job satisfaction from 1 to 7
free_will_T1 <- runif(num_rows, min = 1, max = 6)
free_will_T2 <- runif(num_rows, min = 1, max = 6)
job_satisfaction_T1 <- runif(num_rows, min = 1, max = 7)
job_satisfaction_T2 <- runif(num_rows, min = 1, max = 7)

# Simulating job autonomy scores at two time points, 
# also on a scale from 1 to 7
job_autonomy_T1 <- runif(num_rows, min = 1, max = 7)
job_autonomy_T2 <- runif(num_rows, min = 1, max = 7)

# Creating a data frame with the simulated data
simulated_data <- data.frame(
  ID = ids,
  Free_Will_T1 = free_will_T1,
  Free_Will_T2 = free_will_T2,
  Job_Satisfaction_T1 = job_satisfaction_T1,
  Job_Satisfaction_T2 = job_satisfaction_T2,
  Job_Autonomy_T1 = job_autonomy_T1,
  Job_Autonomy_T2 = job_autonomy_T2
)

# Viewing the first few rows of the simulated dataset
head(simulated_data)
