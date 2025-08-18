source("R/Formate_climate_data_for_rabbit.R")

# Get arguments from command line
args <- commandArgs(trailingOnly = TRUE)


download_location <- sub("/$", "", args[1])   # remove traling / in case it's added on submission

a <- strsplit(download_location, "/")[[1]]
result_dir <- paste("final_files", a[length(a)], sep = "/")

year_min <- as.integer(args[2])
year_max <- as.integer(args[3])

if (args[4] == "peninsula") {
  coord_file = "data/coordinates_peninsula_500_EPSG4326.txt" 
} else if (args[4] == "donana") {
  coord_file = "data/coordinates_donana_500_EPSG4326.txt" 
} else {
  stop("files for coordinates only have two options: 'donana' or 'peninsula'")
}


calculate_BM_cDM(download_location = download_location, 
                 coord_file = coord_file, 
                 year_min = year_min,
                 year_max = year_max,
                 result_dir = result_dir,
                 temperature_type = "minmax")

