# ----------- read csv function
get_data <- function(file) {
  readr::read_csv(file, col_types = readr::cols())
}

# ----------- summary by crash Year
summarise_crashes <- function(df) {
  df %>%
    dplyr::count(crashYear, name = "number_crashes")
}

# ------------ plot crashes by Year
plot_crash_yearly <- function(df) {
  ggplot2::ggplot(df, ggplot2::aes(x = crashYear, y = number_crashes)) +
    ggplot2::geom_line() +
    ggplot2::geom_point() +
    ggplot2::theme_minimal() +
    ggplot2::labs(title = "Crashes per Year",
                  x = "Year", y = "Number of Crashes")
}

# ------------- convert X/Y to points
convert_to_crs <- function(crash_data) {
  stopifnot(is.data.frame(crash_data))
 # check if data X/Y
  if (!all(c("X", "Y") %in% names(crash_data))) {
    stop("convert_to_crs(): expected columns X and Y in crash_data.")
  }
  # filter NA then convert
  crashes_sf <- crash_data %>%
    dplyr::filter(!is.na(X), !is.na(Y)) %>%
    sf::st_as_sf(coords = c("X", "Y"), crs = 2193)
  
  crashes_sf
}

# --------------- modelling function
# crahes modelling
build_crashes_modelling <- function(crash_data) {
  clean_region <- function(x) {
    x %>%
      stringr::str_to_lower() %>%
      stringr::str_squish()
  }
  
  crash_data %>%
    dplyr::filter(crashYear >= 2018, crashYear <= 2025) %>%
    dplyr::mutate(
      severity_bin = dplyr::if_else(
        crashSeverity %in% c("Fatal Crash", "Serious Crash"),
        1L, 0L
      ),
      severity_cat = dplyr::if_else(
        severity_bin == 1L,
        "Severe (fatal/serious)",
        "Non-severe"
      ),
      period = dplyr::case_when(
        crashYear <= 2019 ~ "Pre",
        crashYear %in% c(2020, 2021) ~ "Covid",
        crashYear >= 2022 ~ "Post",
        TRUE ~ NA_character_
      ),
      # VRU flags, check if NAs
      bicycle = tidyr::replace_na(bicycle, 0),
      moped = tidyr::replace_na(moped, 0),
      motorcycle = tidyr::replace_na(motorcycle, 0),
      pedestrian = tidyr::replace_na(pedestrian, 0),
      vru = dplyr::if_else(
        bicycle > 0 | moped > 0 | motorcycle > 0 | pedestrian > 0,
        1L, 0L
      ),
      region = clean_region(region)
    )
}

# severity modelling
build_severity_summary <- function(crashes_modelling) {
  crashes_modelling %>%
    dplyr::filter(!is.na(period)) %>%
    dplyr::group_by(region, period) %>%
    dplyr::summarise(
      total_crashes = dplyr::n(),
      severe_crashes = sum(severity_bin, na.rm = TRUE),
      severe_per_crash = severe_crashes / total_crashes,
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      period = factor(period, levels = c("Pre", "Covid", "Post"))
    )
}

# create table
extract_or_table <- function(model) {
  broom::tidy(model, conf.int = TRUE, exponentiate = TRUE) %>%
    dplyr::rename(
      OR        = estimate,
      OR_low    = conf.low,
      OR_high   = conf.high,
      p_value   = p.value
    )
}


# ------------- Shiny App
prepare_shiny_data <- function(crashes_modelling, crashes_sf) {
  #check for ID col
  if (!"OBJECTID" %in% names(crashes_modelling) ||
      !"OBJECTID" %in% names(crashes_sf)) {
    stop("prepare_shiny_data(): need OBJECTID column in both tables.")
  }
  
  # join datasets
  crashes_sf %>%
    dplyr::select(OBJECTID, geometry) %>%
    dplyr::right_join(crashes_modelling, by = "OBJECTID") %>%
    sf::st_as_sf()
}

