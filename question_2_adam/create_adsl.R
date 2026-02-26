## cleaning environment
rm(list=ls())

log_con <- file("question_2_adam/adam_run_log.txt", open = "wt")
sink(log_con)
sink(log_con, type = "message")

cat("Program started:", Sys.time(), "\n")

library(metacore)
library(metatools)
library(pharmaverseraw)
library(pharmaversesdtm)
library(tidyverse)
library(admiral)

## reading input SDTM data
dm <- pharmaversesdtm::dm
vs <- pharmaversesdtm::vs
ex <- pharmaversesdtm::ex
ds <- pharmaversesdtm::ds
ae <- pharmaversesdtm::ae

## turning SAS blank strings into R NAs
dm <- convert_blanks_to_na(dm)
vs <- convert_blanks_to_na(vs)
ex <- convert_blanks_to_na(ex)
ds <- convert_blanks_to_na(ds)
ae <- convert_blanks_to_na(ae)

adsl <- dm %>%
  select(-DOMAIN)

### reading exposure data
ex_ext <- ex %>%
  derive_vars_dtm(
    dtc = EXSTDTC,
    new_vars_prefix = "EXST",
  ) %>% 
  derive_vars_dtm(
    dtc = EXENDTC,
    new_vars_prefix = "EXEN",
    time_imputation = "last"
  )

adsl <- adsl %>%
  ## deriving treatment start dates
  derive_vars_merged(
    dataset_add = ex_ext,
    ## defining a valid dose (EXDOSE > 0) or (EXDOSE=0 and EXTRT contains placebo)
    filter_add = (EXDOSE > 0 |
                    (EXDOSE == 0 &
                       str_detect(EXTRT, "PLACEBO"))) & !is.na(EXSTDTM),
    new_vars = exprs(TRTSDTM = EXSTDTM, TRTSTMF = EXSTTMF),
    order = exprs(EXSTDTM, EXSEQ),
    mode = "first", ## first observation selected (first exposure record)
    by_vars = exprs(STUDYID, USUBJID)
  ) %>% 
  ## deriving treatment end dates
  derive_vars_merged(
    dataset_add = ex_ext,
    filter_add = (EXDOSE > 0 |
                    (EXDOSE == 0 &
                       str_detect(EXTRT, "PLACEBO"))) & !is.na(EXENDTM),
    new_vars = exprs(TRTEDTM = EXENDTM, TRTETMF = EXENTMF),
    order = exprs(EXENDTM, EXSEQ),
    mode = "last", ## now, we would like to derive the last treatment end date
    by_vars = exprs(STUDYID, USUBJID)
  )

adsl <- adsl %>%
  derive_vars_dtm_to_dt(source_vars = exprs(TRTSDTM, TRTEDTM))

## grouping variables into the following categories
## defining variables AGEGR9 and AGEGR9N (numerical category)
agegr9_lookup <- exprs(
  ~condition,            ~AGEGR9, ~AGEGR9N,
  is.na(AGE),          "Missing",        4,
  AGE < 18,                "<18",        1,
  between(AGE, 18, 50),  "18-50",        2,
  !is.na(AGE),             ">50",        3
)

adsl <- adsl %>%
  ## deriving variables using admiral
  derive_vars_cat(
    definition = agegr9_lookup
  ) %>% 
  ## defining ITTFL flag based on whether the variable ARM is missing or not
  mutate(
    ITTFL = if_else(!is.na(ARM), "Y", "N")
  )

adsl <- adsl %>%
  derive_vars_extreme_event(
    by_vars = exprs(STUDYID, USUBJID),
    ## list of events 
    ## last complete date of vital assessment
    events = list(
      event(
        dataset_name = "vs",
        order = exprs(VSDTC, VSSEQ),
        ## valid test result and date VSDTC not missing
        condition = !is.na(VSSTRESN) & !is.na(VSSTRESC) & !is.na(VSDTC),
        mode='last',
        set_values_to = exprs(
          LSTALVDT = convert_dtc_to_dt(VSDTC, highest_imputation = "M"),
          seq = VSSEQ
        ),
      ),
      ## last complete date of onset of adverse events
      event(
        dataset_name = "ae",
        order = exprs(AESTDTC, AESEQ),
        condition = !is.na(AESTDTC),
        mode='last',
        set_values_to = exprs(
          LSTALVDT = convert_dtc_to_dt(AESTDTC, highest_imputation = "M"),
          seq = AESEQ
        ),
      ),
      ## last complete disposition date
      event(
        dataset_name = "ds",
        order = exprs(DSSTDTC, DSSEQ),
        condition = !is.na(DSSTDTC),
        mode='last',
        set_values_to = exprs(
          LSTALVDT = convert_dtc_to_dt(DSSTDTC, highest_imputation = "M"),
          seq = DSSEQ
        ),
      ),
      ## last date of treatment administration where participant received a valid dose
      event(
        dataset_name = "adsl",
        condition = !is.na(TRTEDT),
        set_values_to = exprs(
          LSTALVDT = TRTEDT, 
          seq = 0),
      )
    ),
    source_datasets = list(vs=vs, ae = ae, ds = ds, adsl = adsl),
    tmp_event_nr_var = event_nr,
    order = exprs(LSTALVDT, seq, event_nr),
    mode = "last", ## extract the last event 
    new_vars = exprs(LSTALVDT)
  )

adsl

save(adsl, file = "question_2_adam/output/adsl_output.RData")

cat("Program completed successfully:", Sys.time(), "\n")

sink(type = "message")
sink()
close(log_con)
