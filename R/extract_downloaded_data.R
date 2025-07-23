# Incremental processing of climate files
# This code processes files only if they haven't been processed yet
# and appends new data to the existing CSV

library(raster)
library(dplyr)
library(tidyr)
library(stringr)
library(lubridate)

args = commandArgs(trailingOnly = T)

# Function to process a single file
format_future_ts_climate <- function(file) {
  message(paste("Processing file:", basename(file)))
  
  opt <- stringr::str_split(file, "_")[[1]]
  nc <- raster::brick(file)

df <- data.frame()
  
  total_rows <- nrow(gps)
  chunk_size = 100000
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
  
  output_dir <- paste(spat_scale, opt[5], opt[6], sep = "_")
  
  if(!dir.exists(output_dir)){
    dir.create(output_dir)
  }
  
  for(i in c(2:ncol(df))) {
  year <- as.integer(substr(colnames(df)[i], 2, 5))
  fileName <- paste(opt[4], gsub("\\.", "_", colnames(df)[i]), sep = "_")
  write.table(df[,i], file = file.path(output_dir, paste0(fileName, ".txt")),
   row.names = F, col.names = F)
  }
  
}

files <- list.files(pattern = "CHELSAcmip5ts", recursive = T, full.names = T)
gps <- read.table(args[1])
spat_scale <- args[2]

lapply(files, format_future_ts_climate) 
    
message("Processing complete. Data saved.")


