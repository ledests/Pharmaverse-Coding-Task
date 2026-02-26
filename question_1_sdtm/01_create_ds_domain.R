## cleaning environment
rm(list=ls())

log_con <- file("question_1_sdtm/sdtm_run_log.txt", open = "wt")
sink(log_con)
sink(log_con, type = "message")

cat("Program started:", Sys.time(), "\n")

library(pharmaverseraw)
library(pharmaversesdtm)
library(sdtm.oak)
library(tidyverse)

ds_raw <- pharmaverseraw::ds_raw
ds_fin_sample <- pharmaversesdtm::ds

## reading the dm domain
dm <- pharmaversesdtm::dm

## reading study controlled terminology file from github
data_sdtm <- read.csv('question_1_sdtm/data_in/sdtm_ct.csv')

ds_raw <- ds_raw %>%
  generate_oak_id_vars(
    pat_var = "PATNUM", ## patient number
    raw_src = "ds_raw" ## raw source dataset
  )

ds <-
  ## target variable DSTERM based on 'IT.DSTERM' (from Subject_Disposition_aCRF)
  assign_no_ct(
    raw_dat = ds_raw,
    raw_var = "IT.DSTERM",
    tgt_var = "DSTERM",
    id_vars = oak_id_vars()
  )

ds <- ds %>%
  # Map DSDECOD raw_var=IT.DSDECOD, tgt_var=DSDECOD
  assign_no_ct(
    raw_dat = ds_raw,
    raw_var = "IT.DSDECOD",
    tgt_var = "DSDECOD",
    id_vars = oak_id_vars()
  ) %>% 
  # Map OTHERSP 
  assign_no_ct(
    raw_dat = ds_raw,
    raw_var = "OTHERSP",
    tgt_var = "OTHERSP",
    id_vars = oak_id_vars()
  ) %>% 
  # Map VISITNUM using raw_var INSTANCE, tgt_var=VISITNUM
  assign_ct(
    raw_dat = ds_raw,
    raw_var = "INSTANCE",
    tgt_var = "VISITNUM",
    ct_spec = data_sdtm,
    ct_clst = "VISITNUM",
    id_vars = oak_id_vars()
  ) %>%
  # Map IT.DSSTDAT into DSSTDTC in ISO8601 format
  assign_datetime(
    raw_dat = ds_raw,
    raw_var = "IT.DSSTDAT",
    tgt_var = "DSSTDTC",
    raw_fmt = c("m-d-y")
  ) %>%
  # Map DSDTC using both DSDTCOL and DSTMCOL 
  assign_datetime(
    raw_dat = ds_raw,
    raw_var = c("DSDTCOL","DSTMCOL"),
    tgt_var = "DSDTC",
    raw_fmt = c("m-d-y",'H:M'),
    id_vars = oak_id_vars()
  ) %>% 
  ## DSCAT defined as 'PROTOCOL MILESTONE' if DSDECOD =='Randomized'
  ## otherwise, defined as 'DISPOSITION EVENT'
  mutate(DSCAT=case_when(
    DSDECOD == 'Randomized' ~ 'PROTOCOL MILESTONE',
    T ~ 'DISPOSITION EVENT'
  )) %>% 
  mutate(DSDECOD = if_else(!is.na(OTHERSP),OTHERSP,DSDECOD),
         DSTERM = if_else(!is.na(OTHERSP),OTHERSP,DSTERM),
         DSCAT = if_else(!is.na(OTHERSP),'OTHER EVENT',DSCAT))

## warning message: These terms could not be mapped per the controlled terminology: 
## "Ambul Ecg Removal", "Unscheduled 6.1", "Unscheduled 1.1"
## "Unscheduled 5.1", "Unscheduled 4.1", "Unscheduled 8.2", and "Unscheduled 13.1"

## inconsistencies in terminology from raw file
data_sdtm %>% 
  ## mapping from VISITNUM
  filter(codelist_code=='VISITNUM') %>% 
  ## determining term_values for terms that could not be mapped
  filter(grepl('Unscheduled',collected_value) | grepl('Ambul',collected_value))

## Ambul ECG Removal - 6 (difference in capitalization)
## other unscheduled visits are '1.1', '5.1', etc (based on pharmaversesdtm::ds)

## VISITNUM mapped in all caps
ds %>% count(VISITNUM)

ds <- ds %>% 
  ## mapping according to terminology in SDTM file
  mutate(VISITNUM=case_when(
    VISITNUM=='AMBUL ECG REMOVAL' ~ '6',
    grepl('UNSCHEDULED',VISITNUM) ~ substr(VISITNUM,13,15),
    T ~ VISITNUM
  )) 

## preparing the final dataset
ds_final <- ds %>%
  dplyr::mutate(
    ## updating variable format for consistency with SDTM guidelines
    STUDYID = ds_raw$STUDY,
    DOMAIN = "DS",
    USUBJID = paste0("01-", ds_raw$PATNUM),
    VISIT = toupper(ds_raw$INSTANCE),
    VISITNUM = as.numeric(VISITNUM),
    DSTERM = toupper(DSTERM),
    DSDECOD = toupper(DSDECOD)
  ) %>% 
  ## deriving sequence based on subject ID
  derive_seq(
    tgt_var = "DSSEQ",
    rec_vars = c("USUBJID")
  ) %>% 
  ## deriving Study Day of Start of Disposition Event 
  ## using reference from DM domain and start date/time of disposition event
  ## saving it into the DSSTDY variable
  derive_study_day(
    sdtm_in = .,
    dm_domain = dm,
    tgdt = "DSSTDTC",
    refdt = "RFXSTDTC",
    study_day_var = "DSSTDY"
  ) %>% 
  ## selecting relevant variables for DS domain
  select(
    "STUDYID","DOMAIN","USUBJID", 
    "DSSEQ", "DSTERM", "DSDECOD", "DSCAT", "VISITNUM", "VISIT", "DSDTC",
    "DSSTDTC","DSSTDY"
  )

## extracting attribute names for the columns (based on sample SDTM DS domain from pharmaversesdtm::ds)
atr_ds <- sapply(ds_fin_sample, function(x) attr(x, "label"))

## assigning the attribute names to the created SDTM DS domain
for (v in colnames(ds_final)) {
  attr(ds_final[[v]], "label") <- atr_ds[[v]]
}

ds_final

cat("Program completed successfully:", Sys.time(), "\n")

sink(type = "message")
sink()
close(log_con)
  
  
