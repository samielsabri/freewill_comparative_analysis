# Belief in Free Will Analysis

## Overview

This repository is dedicated to the analysis of belief in free will and job satisfaction. The analysis is a reproduction of a paper titled 'Agency Beliefs Over Time and Across Cultures: Free Will Beliefs Predict Higher Job Satisfaction' by Gilad Feldman, Jiing-Lih Farh, and Kin Fai Ellick Wong (2018), available here: 
https://doi.org/10.1177/014616721773926


## File Structure

The repo is structured as:

-   `input/data` contains the data sources used in analysis including the raw data.
Due to size constraints, the raw World Values Survey Data is not included in the repository (1.3GB). However, it is easily accessible on https://www.worldvaluessurvey.org/WVSDocumentationWVL.jsp as 'WVS TimeSeries 1981 2022 Csv v4 0.zip' and should be added to `input/data/study_3` by the user, in order for this project to be fully reproducible.
-   `outputs/data` contains the cleaned datasets that were constructed.
-   `outputs/paper` contains the files used to generate the paper, including the Quarto document and reference bibliography file, as well as the PDF of the paper. 
-  `outputs/ssrp_report` contains the Quarto document and reference bibliography file that is the replication report for 'Social Science Reproduction (SSRP)'
-   `scripts` contains the R scripts used to simulate, download and clean data.

## How to Use

1. Clone the repository: `git clone https://github.com/samielsabri/freewill-analysis.git`
2. Navigate to the repository: `cd freewill-analysis`
3. Explore the folders and files as needed.

## License

This project is licensed under the [MIT License](LICENSE). You are free to use, modify, and distribute the code.

## LLM usage

This project used Large Language Models at various points. Some aspects of the R scripts, as well as parts of the abstract and introduction of paper.qmd were written with the help of Chat-GPT3 and the entire chat history is available in 'inputs/llm/usage.txt'

---

**Code and data are available at: [GitHub Repository](https://github.com/samielsabri/freewill-analysis)**
