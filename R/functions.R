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