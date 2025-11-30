library(targets)
library(tarchetypes)

files_dir <- path.expand("~/Documents/git-repos/Files")

tar_source("R")   

tar_option_set(
  packages = c("readr", "dplyr", "ggplot2", "sf", "lubridate", "tidyr", 
               "stringr", "broom")
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
  
  # severe proportion by period & region (Pre/Covid/Post)
  tar_target(
    severity_summary,
    build_severity_summary(crashes_modelling)
  ),
  
  # logistic model for severity ~ period
  tar_target(
    model_severity_period,
    glm(
      severity_bin ~ period,
      data = crashes_modelling,
      family = binomial(link = "logit")
    )
  ),
  
  tar_target(
    OR_severity_period,
    extract_or_table(model_severity_period)
  ),
  
  # logistic model for VRU ~ period
  tar_target(
    model_vru_period,
    glm(
      vru ~ period,
      data = crashes_modelling,
      family = binomial(link = "logit")
    )
  ),
  
  tar_target(
    OR_vru_period,
    extract_or_table(model_vru_period)
  ),
  
  # --------------- Shiny App ------------
  # dataset for Shiny: join modelling vars + geometry
  tar_target(
    crashes_interactive,
    prepare_shiny_data(crashes_modelling, crashes_sf)
  ),
  
  # -------------- export for Shiny App ------------
  tar_target(
    crashes_interactive_rds,
    {
      dir.create("Outputs", showWarnings = FALSE)
      saveRDS(crashes_interactive, "Outputs/crashes_interactive.rds")
      "Outputs/crashes_interactive.rds"
    },
    format = "file"
  ),
  
  # ---------------- Plot output ---------------------
  tar_target(
    crash_plot,
    plot_crash_yearly(summary_table)
  )
)