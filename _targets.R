library(targets)
library(tarchetypes)

files_dir <- path.expand("~/Documents/git-repos/Files")
results_dir <- "Results"

tar_source("R")   

tar_option_set(
  packages = c("readr", "dplyr", "ggplot2", "sf", "lubridate")
)

list(
  # ---------------- Input file paths ----------------
  tar_target(
    crash_file,
    file.path(files_dir, "Crash_Analysis_System_(CAS)_data.csv"),
    format = "file"
  ),
  
  tar_target(
    dictionary_file,
    file.path(files_dir, "crash_data_dictionary.csv"),
    format = "file"
  ),
  
  # ---------------- Load data -----------------------
  tar_target(
    crash_data,
    get_data(crash_file)
  ),
  
  tar_target(
    dictionary_data,
    get_data(dictionary_file)
  ),
  
  # ---------------- Example modelling step ---------
  tar_target(
    summary_table,
    summarise_crashes(crash_data)
  ),
  
  # ---------------- Plot output ---------------------
  tar_target(
    crash_plot,
    plot_crash_yearly(summary_table)
  )
)