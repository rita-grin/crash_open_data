NZ Crash Analysis: Severity & VRU Trends (2018–2024)

This project explores crash severity and vulnerable road-user (VRU) involvement in Aotearoa New Zealand using open CAS crash data. It examines patterns across regions and time periods (Pre-Covid, Covid, Post-Covid) and includes modelling, visualisation, and an interactive Shiny dashboard.

The goal is to identify high-risk patterns and regional variation in severe crashes and VRU exposure to support road-safety decisions aligned with Road to Zero priorities.

Data: 
* CAS open crash dataset (Waka Kotahi),
* Supporting population estimates (Stats NZ). 

Crash years: 2018–2024. 
Spatial reference: NZTM / EPSG 2193

Tools & workflow
This project is built using R (targets, dplyr, sf, ggplot2, broom, leaflet, shiny), reproducible pipeline implemented with {targets}, interactive mapping via Shiny

How to run

1. Clone the repository
git clone https://github.com/rita-grin/crash_open_data
cd crash_open_data

2. Build analysis workflow
library(targets)
tar_make()

3. Launch Shiny dashboard
shiny::runApp("app")

Outputs:   
* Severe crash trend visualisation,
* VRU involvement trend,
* Odds ratio modelling results
* Interactive regional crash viewer (Shiny)

Deployment considerations:   
* Automate pipeline refresh using GitHub Actions,
* Extend with speed-limit change layers and exposure metrics (VKT, mobility)

Future work:   
* Before–after modelling of speed-limit interventions (e.g., 50→30 km/h),
* Integration with traffic-flow and population normalisation,
* Refinement of regional prioritisation

Author

Margarita Grishechkina, Master of Applied Data Science, University of Canterbury, Christchurch, New Zealand

Licence

Open-source project based on publicly available datasets
