get_data <- function(file) {
  readr::read_csv(file, col_types = readr::cols())
}

summarise_crashes <- function(df) {
  df %>%
    dplyr::count(crashYear, name = "number_crashes")
}

plot_crash_yearly <- function(df) {
  ggplot2::ggplot(df, ggplot2::aes(x = crashYear, y = number_crashes)) +
    ggplot2::geom_line() +
    ggplot2::geom_point() +
    ggplot2::theme_minimal() +
    ggplot2::labs(title = "Crashes per Year",
                  x = "Year", y = "Number of Crashes")
}