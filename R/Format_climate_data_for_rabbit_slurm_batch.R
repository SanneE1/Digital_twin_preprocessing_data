source("R/Formate_climate_data_for_rabbit.R")

# Get arguments from command line
args <- commandArgs(trailingOnly = TRUE)

array_id <- as.integer(args[1])
total_arrays <- as.integer(args[2])

download_location <- sub("/$", "", args[3])
year_min <- as.integer(args[4])
year_max <- as.integer(args[5])

if (args[6] == "peninsula") {
  coord_file = "data/coordinates_peninsula_500_EPSG4326.txt" 
} else if (args[6] == "donana") {
  coord_file = "data/coordinates_donana_500_EPSG4326.txt" 
} else {
  stop("files for coordinates only have two options: 'donana' or 'peninsula'")
}

# Read the coordinate file to get total number of rows
total_rows <- nrow(read.table(coord_file))

# Calculate chunk size and start/end rows
chunk_size <- ceiling(total_rows / total_arrays)
start_row <- (array_id - 1) * chunk_size + 1
end_row <- min(array_id * chunk_size, total_rows)

# Extract row index ranges
row_indices <- c(start_row:end_row)

calculate_BM_cDM(download_location = download_location, 
                 year_min = year_min,
                 year_max = year_max,
                 coord_file = coord_file, 
                 row_indices = row_indices)




