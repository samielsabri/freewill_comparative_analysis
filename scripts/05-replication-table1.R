#### Preamble ####
# Purpose: Replicate Figures and Tables
# Author: Sami El Sabri, Liban Timir
# Date: 10 February 2023
# Contact: sami.elsabri@mail.utoronto.ca
# License: MIT


#### Workspace setup ####
library(tidyverse)
library(psych)
library(ggplot2)
library(knitr)

#### Read data ####
satisfaction_data <- read_csv("inputs/data/study_1/FW satisfaction-Study 1-data.csv")

# Clean data #
# satisfaction_data <- satisfaction_data %>% select(freewill, JS, W2JS)

# visualize data #

satisfaction_data_summary <- satisfaction_data %>% summarize(mean_freewill = round(mean(freewill, na.rm = TRUE),2), 
                                                             mean_js1 = round(mean(JS, na.rm = TRUE),2),
                                                             mean_js2 = round(mean(W2JS, na.rm = TRUE),2),
                                                             sd_freewill = round(sd(freewill,  na.rm = TRUE),2),
                                                             sd_js1 = round(sd(JS, na.rm = TRUE),2),
                                                             sd_js2 = round(sd(W2JS,  na.rm = TRUE),2))

satisfaction_data_cor_matrix <- cor(satisfaction_data[, c("freewill", "JS", "W2JS")], use = "complete.obs")
satisfaction_data_cor_matrix <- round(satisfaction_data_cor_matrix, 3)
# satisfaction_data_cor_matrix <- as.data.frame(satisfaction_data_cor_matrix[lower.tri(satisfaction_data_cor_matrix)])

freewill_items <- satisfaction_data[, c("A11", "A12", "A13", "A14", "A15", "A16", "A17", "A18")]
alpha_freewill <- alpha(freewill_items)
alpha_freewill <- alpha_freewill$total$raw_alpha
alpha_freewill <- round(alpha_freewill,2)

js1_items <- satisfaction_data[, c("G124", "G125", "G126")]
alpha_js1 <- alpha(js1_items)
alpha_js1 <- alpha_js1$total$raw_alpha
alpha_js1 <- round(alpha_js1,2)

js2_items <- satisfaction_data[, c("W2E87", "W2E88", "W2E89")]
alpha_js2 <- alpha(js2_items)
alpha_js2 <- alpha_js2$total$raw_alpha
alpha_js2 <- round(alpha_js2,2)

final_table <- data.frame(
  Variable = c("Belief in Free Will (T1)", "Job Satisfaction (T1)", "Job Satisfaction (T2)"),
  "Reliability Coefficient" = c(alpha_freewill, alpha_js1, alpha_js2),
  Mean = c(satisfaction_data_summary$mean_freewill, 
           satisfaction_data_summary$mean_js1, 
           satisfaction_data_summary$mean_js2),
  SD = c(satisfaction_data_summary$sd_freewill, 
         satisfaction_data_summary$sd_js1, 
         satisfaction_data_summary$sd_js2),
  "Belief in Free Will (T1)" = c(NA, satisfaction_data_cor_matrix[1,2], satisfaction_data_cor_matrix[1,3]),
  "Job Satisfaction (T1)" = c(NA, NA, satisfaction_data_cor_matrix[2,3]),
  "Job Satisfaction (T2)" = c(NA, NA, NA),
  check.names = FALSE
)
