# Incremental processing of climate files
# This code processes files only if they haven't been processed yet
# and appends new data to the existing CSV

library(raster)
library(dplyr)
library(tidyr)
library(stringr)
library(lubridate)

# File to store processed files
processed_files_log <- "processed_files_log.rds"
output_csv <- "CHELSA_future_data.csv"

# Check if the log of processed files exists, if not create it
if (!file.exists(processed_files_log)) {
  processed_files <- character(0)
  saveRDS(processed_files, processed_files_log)
} else {
  processed_files <- readRDS(processed_files_log)
}

# Check if output CSV exists, if not create an empty dataframe with the right structure
if (!file.exists(output_csv)) {
  existing_data <- data.frame(
    ID = numeric(),
    date = as.Date(character()),
    value = numeric(),
    variable = character(),
    model = character(),
    scenario = character(),
    X = integer(),
    Y = integer(),
    stringsAsFactors = FALSE
  )
} else {
  existing_data <- read.csv(output_csv, stringsAsFactors = FALSE)
  # Convert date column back to Date type
  existing_data$date <- as.Date(existing_data$date)
}

# Function to process a single file
format_future_ts_climate <- function(file) {
  message(paste("Processing file:", basename(file)))
  
  opt <- stringr::str_split(file, "_")[[1]]
  nc <- raster::brick(file)
  
  df <- data.frame()
  
  total_rows <- nrow(gps)
  chunk_size = 1000
  num_chunks <- ceiling(total_rows / chunk_size)
  
  for (i in 1:num_chunks) {
    # Calculate start and end indices for current chunk
    start_idx <- (i - 1) * chunk_size + 1
    end_idx <- min(i * chunk_size, total_rows)
    
    # Extract current chunk
    current_chunk <- gps[start_idx:end_idx, ]
    
  df_chunk <- raster::extract(nc, current_chunk, method="bilinear", df = TRUE) 
  df <- bind_rows(df, df_chunk)
  }
  
  output_dir <- paste(opt[5], opt[6], sep = "_")
  
  if(!dir.exists(output_dir)){
    dir.create(output_dir)
  }
  
  for(i in c(2:ncol(df))) {
  fileName <- paste(opt[4], gsub("\\.", "_", colnames(df)[i]), sep = "_")
  write.table(df[,i], file = file.path(output_dir, paste0(fileName, ".txt")))
  }
  
}

files <- list.files(pattern = ".nc", recursive = T, full.names = T)
gps <- read.table("coordinates_peninsula_500_EPSG4326.txt")

# Identify files that haven't been processed yet
files_to_process <- files[!files %in% processed_files]

if (length(files_to_process) == 0) {
  message("No new files to process.")
} else {
  message(paste("Found", length(files_to_process), "new files to process."))
  
  # Process new files
  lapply(files_to_process, format_future_ts_climate) 
    
    # Update and save the list of processed files
    processed_files <- c(processed_files, files_to_process)
    saveRDS(processed_files, processed_files_log)
    
    message("Processing complete. Data saved.")
  } 

