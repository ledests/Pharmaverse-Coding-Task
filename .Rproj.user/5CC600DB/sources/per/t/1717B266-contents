## cleaning environment
rm(list=ls())

log_con <- file("question_3_tlg/01_tlg_run_log.txt", open = "wt")
sink(log_con)
sink(log_con, type = "message")

cat("Program started:", Sys.time(), "\n")

library(gtsummary)
library(pharmaverseraw)
library(pharmaversesdtm)
library(tidyverse)
library(gt)

## reading data
adae_data <- pharmaverseadam::adae
adsl_data <- pharmaverseadam::adsl

adae_summary_table <- adae_data %>% 
  ## filtering only treatment-emergent AE records
  filter(TRTEMFL=='Y') %>% 
  ## creating tbl_hierarchical object
  tbl_hierarchical(
    ## variables: AESOC (Primary system organ class), AETERM (Reported term for the adverse event)
    variables = c(AESOC,AETERM),
    ## by treatment arm
    by = ACTARM,
    ## using subject ID as the ID
    id = USUBJID,
    ## denominator based on adsl_data 
    denominator = adsl_data,
    ## include overall row 
    overall_row = TRUE,
    ## label variable
    label = "..ard_hierarchical_overall.." ~ "Treatment Emergent AEs"
  ) %>% 
  ## including total column with all subjects
  add_overall(last=T) %>% 
  ## sorting by descending frequency (default for sort(hierarchical())
  sort_hierarchical()

## exporting to PDF using gt 
adae_summary_table %>%
  as_gt() %>%
  gtsave("question_3_tlg/output/ae_summary_table.pdf")

cat("Program completed successfully:", Sys.time(), "\n")

sink(type = "message")
sink()
close(log_con)
