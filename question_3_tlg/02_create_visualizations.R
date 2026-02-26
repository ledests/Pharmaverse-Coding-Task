## cleaning environment
rm(list=ls())

log_con <- file("question_3_tlg/02_tlg_run_log.txt", open = "wt")

sink(log_con)
sink(log_con, type = "message")

cat("Program started:", Sys.time(), "\n")

library(gtsummary)
library(pharmaverseraw)
library(pharmaversesdtm)
library(pharmaverseadam)
library(tidyverse)

### reading adae data
adae_data <- pharmaverseadam::adae

###############
#### first plot

## using AESEV as the fill variable
## and ARM as the variable in the x-axis
## count by AE severity and treatment ARM (y-axis)
bar_plot_adae <- adae_data %>% 
  ggplot(aes(x=ARM,fill=AESEV))+
  ## generate a bar plot
  geom_bar()+
  ## updating labels to match sample plot
  labs(x='Treatment Arm',
       y='AE severity distribution by treatment',
       fill='Severity/Intensity',
       title='AE severity distribution by treatment')

ggsave('question_3_tlg/output/ae_bar_plot.png',bar_plot_adae)

###############
##### second plot

## computing number of distinct patients
n_total <- n_distinct(adae_data$USUBJID) 

## computing Clopper - Pearson CIs 
ae_vars_ci <- adae_data %>%
  ## computing incidence for each adverse event
  group_by(AETERM) %>%
  summarise(
    events = n_distinct(USUBJID),  
    .groups = "drop"
  ) %>%
  mutate(
    n = n_total,
    ## computing incidence in percentage
    incidence = events / n * 100,
    ## computing standard error of a proportion (incidence), then converting to percentage scale
    se = sqrt((events / n) * (1 - events / n) / n) * 100,
    ## given that we are dealing with percentages, we truncate the 95% CIs at 0% and 100%
    ## 95% CIs computed as incidence +- 1.96*se
    lower = pmax(0, incidence - 1.96 * se),
    upper = pmin(100, incidence + 1.96 * se)
  )

## using computed dataset of Clopper-Pearson CIs
ae_ci_plot_adae <- ae_vars_ci %>% 
  ## arrange in descending order by incidence
  arrange(desc(incidence)) %>% 
  ## pull 10 most frequent adverse events (as descending order by incidence)
  slice(1:10) %>% 
  ## order AETERM based on incidence value so that AEs with the most incidence are at the top
  ggplot(aes(x = incidence, y = reorder(AETERM, incidence))) +
  geom_point(size = 3) +
  ## plotting CIs
  geom_errorbar(aes(xmin = lower, xmax = upper), width = 0.2) +
  ## x-axis labels in percentage
  scale_x_continuous(labels = function(x) paste0(round(x,1), "%")) + 
  ## updating labels to match sample plot
  labs(x='Percentage of Patients (%)',y='',
       title='Top 10 Most Frequent Adverse Events',
       subtitle='n = 225 subjects; 95% Clopper-Pearson CIs')

ggsave('question_3_tlg/output/ae_ci_plot.png',ae_ci_plot_adae)

cat("Program completed successfully:", Sys.time(), "\n")

sink()
sink(type = "message")
close(log_con)

