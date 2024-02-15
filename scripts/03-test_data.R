#### Preamble ####
# Purpose: Tests the cleaned data provided by Feldman et al. (2017) and by WVS
# Author: Sami El Sabri & Liban Timir
# Date: 15 February 2024
# Contact: sami.elsabri@mail.utoronto.ca, liban.timir@mail.utoronto.ca
# License: MIT
# Pre-requisites: 02-data_cleaning.R


#### Workspace setup ####
library(tidyverse)
library(testthat)
# [...UPDATE THIS...]

#### Read in data ####
wvs_data_usa <- read_csv(here::here('outputs/data/wvs_data_usa.csv'))

#### Test data ####
test_that("Free Will scale scores are within the 1-6 range", {
  expect_true(all(wvs_data_usa$freewill >= 1 & wvs_data_usa$freewill <= 6), 
              info = "There are scores outside the 1-6 range in the Free Will 
              scale")
})

test_that("Job Satisfaction scale values are within the 1-7 range", {
  expect_true(all(wvs_data_usa$job_satisfaction >= 1 & 
                    wvs_data_usa$job_satisfaction <= 7),
              info = "Job Satisfaction scale values are out of the 1-7 range")
})

test_that("Data types are correct", {
  expect_is(wvs_data_usa$freewill, "numeric", 
            info = "Free Will scale is not numeric")
  expect_is(wvs_data_usa$job_satisfaction, "numeric",
            info = "Job Satisfaction is not numeric")
})

test_that("Dataset has the expected number of rows", {
  expected_number_of_rows <- 12983  
  actual_number_of_rows <- nrow(wvs_data_usa)
  expect_equal(actual_number_of_rows, expected_number_of_rows,
               info = "The dataset does not have the expected number of rows.")
})

test_that("Values in specified columns are positive", {
  columns_to_check <- c("freewill", "job_satisfaction")
  for (column_name in columns_to_check) {
    expect_true(all(your_dataframe[[column_name]] > 0),
                info = paste("Not all values in the", column_name, 
                             "column are positive."))
  }
})


