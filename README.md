
This repository contains solutions to a four-part clinical programming coding assessment. The tasks demonstrate SDTM and ADaM dataset creation, TLF generation, and an LLM-based clinical assistant prototype using Python.

## Repository Structure

Coding task/
- question_1_sdtm/
  data_in/
  output/

- question_2_adam/
  output/

- question_3_tlg/
  output/

- question_4_llm/
  data_in/

- Coding task.Rproj
- README.md

Task 1 – SDTM DS Domain Creation

Script: question_1_sdtm/01_create_ds_domain.R
Creates the DS domain using pharmaverse tooling and standard SDTM conventions, output (ds_final) saved to question_1_sdtm_output/ds_domain_output.RData. 

Task 2 – ADaM ADSL Dataset

Script: question_2_adam/create_adsl.R
Constructs an ADSL dataset following CDISC ADaM standards using pharmaverse and admiral, output (adsl) saved to: question_2_adam/output/adsl_output.RData.

Task 3 – TLF Generation

Script 1: question_3_tlg/01_create_ae_summary_table.R – Generates AE summary tables (question_3_tlg/output/ae_summary_table.pdf)
Script 2: 02_create_visualizations.R – Produces visualizations of AE data (question_3_tlg/output/ae_bar_plot.png and question_3_tlg/output/ae_ci_plot.png)

Outputs saved to question_3_tlg/output/

Task 4 – LLM Clinical Assistant Prototype

Script 1: question_4_llm/lm_clinical_assistant.py – LLM-based query processor (using Gemini AI)
Script 2: question_4_llm/llm_test_script.py – Runs example queries

The example output from Script 2 is saved to question_4_llm/llm_sample_output.html (also saved as a PDF)

## Running tasks 1-3

1. Open the .RProj file.
2. Ensure working directory is set to the root folder ("Coding task").
3. Install required packages: gtsummary, gt, pharmaverseraw, pharmaversesdtm, pharmaverseadam, tidyverse, admiral, sdtm.oak, metacore, metatools
4. Run scripts in each task folder.

## Running task 4

1. Navigate to question_4_llm/
2. Install required packages: pandas, json, os, google-genai, python-dotenv
3. Make sure an API key is set-up through an .env file
4. Set working directory to question_4_llm
5. Run: python llm_test_script.py

## Environment Variables

The .env file containing the Gemini API key is intentionally excluded from this repository for security reasons. The offline chatbot mode can be used for reproducible execution.

## Execution Logs

The task folders contain log files confirming successful execution/output generation. These logs demonstrate that scripts run without errors in a clean environment.
