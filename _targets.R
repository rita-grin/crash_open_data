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
  
  # -------------- Spatial conversion -----------
  tar_target(
    crashes_sf,
    convert_to_crs(crash_data)
  ),
  
  # ---------------- Modelling ---------
  # crash summary
  tar_target(
    summary_table,
    summarise_crashes(crash_data)
  ),
  
  # modelling df with 2018-2024 time frame
  tar_target(
    crashes_modelling,
    build_crashes_modelling(crash_data)   
  ),
  
  # --------------- Shiny App ------------
  # dataset for Shiny: join modelling vars + geometry
  tar_target(
    crashes_interactive,
    prepare_shiny_data(crashes_modelling, crashes_sf)
  ),
  
  # ---------------- Plot output ---------------------
  tar_target(
    crash_plot,
    plot_crash_yearly(summary_table)
  )
)