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
  
  tar_target(
    pop_file,
    file.path(files_dir, "subnational-population-estimates.xlsx"),
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
  
  tar_target(
    pop_region_raw,
    load_pop_region_raw(pop_file) # from R/functions_pop.R
  ),
  
  tar_target(
    pop_region,
    clean_pop_region(pop_region_raw)  # clean names, drop totals
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
  
  # 2024 severe per 100k by region
  tar_target(
    severity_2024_region,
    build_severity_2024_region(crashes_modelling, pop_region)
  ),
  
  # --------------- Shiny App ------------
  # dataset for Shiny: join modelling vars + geometry
  tar_target(
    crashes_interactive,
    prepare_shiny_data(crashes_modelling, crashes_sf)
  ),
  
  # -------------- export files  ------------
  tar_target(
    crashes_interactive_rds,
    {
      dir.create("Outputs", showWarnings = FALSE)
      saveRDS(crashes_interactive, "Outputs/crashes_interactive.rds")
      "Outputs/crashes_interactive.rds"
    },
    format = "file"
  ),
  
  tar_target(
    severity_2024_region_rds,
    {
      saveRDS(severity_2024_region, "Outputs/severity_2024_region.rds")
      "Outputs/severity_2024_region.rds"
    },
    format = "file"
  ),
  
  tar_target(
    severity_summary_rds,
    {
      saveRDS(severity_summary, "Outputs/severity_summary.rds")
      "Outputs/severity_summary.rds"
    },
    format = "file"
  ),
  
  # ---------------- Plot output ---------------------
  tar_target(
    crash_plot,
    plot_crash_yearly(summary_table)
  ),
  
  tar_target(
    severity_plot,
    plot_severity_period(severity_summary)
  )
)