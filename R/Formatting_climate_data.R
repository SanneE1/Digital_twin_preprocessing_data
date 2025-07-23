
library(dplyr)

##------------------------------------------------------------------------------------------------------------
## Use downloaded data to calculate breeding months and consecutive dry months
##------------------------------------------------------------------------------------------------------------

# Function copied from the geosphere package
daylength <- function(lat, doy) {
  P <- asin(0.39795 * cos(0.2163108 + 2 * atan(0.9671396 * 
                                                 tan(0.0086 * (doy - 186)))))
  a <- (sin(0.8333 * pi/180) + sin(lat * pi/180) * sin(P))/(cos(lat * 
                                                                  pi/180) * cos(P))
  a <- pmin(pmax(a, -1), 1)
  DL <- 24 - (24/pi) * acos(a)
  return(DL)
}

calculate_BM_cDM <- function(download_location, year_min, year_max,
                             coord_file, row_col_file, row_indices) {
  
  # Full file of tas/pr per cell
  files <- list.files(download_location, full.names = T, recursive = T)
  
  # Check time rage for which we have both rain and temperature information
  files_pr <- list.files(download_location, full.names = T, recursive = T, pattern = "pr")
  files_tasmax <- list.files(download_location, full.names = T, recursive = T, pattern = "tasmax")
  files_tasmin <- list.files(download_location, full.names = T, recursive = T, pattern = "tasmin")
  
  tas_time <- stringr::str_extract(files_tasmax, '\\d{4}_\\d{2}_')
  pr_time <- stringr::str_extract(files_pr, '\\d{4}_\\d{2}_')
  
  tas_time[which(!(tas_time %in% pr_time))]
  pr_time[which(!(pr_time %in% tas_time))]
  
  # get some functions and pre-calculations done
  P_B <- function(Temp, D, delta, W) {
    1 / (1 + exp(4.542 - (0.605* Temp) + (0.029 * Temp^2) - (0.006 * D) - (0.017 * delta) - W))
  }
  
  # Daylength
  mL <- c(31,28,31,30,31,30,31,31,30,31,30,31)
  mE <- cumsum(mL)
  
  dL <- lapply(as.list(c(1:12)), function(x) {
    read.table(coord_file)[row_indices,] %>% 
      as.data.frame() %>%
      rowwise() %>%
      mutate(dayL = mean(daylength(V2, c((mE[x] - mL[x]):mE[x])) * 60),  # daylength() returns 
             .keep = "none")}
  ) %>% bind_cols()
  
  # Assume delta is calculated as D_current - D_previous
  ddL <- data.frame(diff_1 = dL[,1] - dL[,12],
                    diff_2 = dL[,2] - dL[,1],
                    diff_3 = dL[,3] - dL[,2],
                    diff_4 = dL[,4] - dL[,3],
                    diff_5 = dL[,5] - dL[,4],
                    diff_6 = dL[,6] - dL[,5],
                    diff_7 = dL[,7] - dL[,6],
                    diff_8 = dL[,8] - dL[,7],
                    diff_9 = dL[,9] - dL[,8],
                    diff_10 = dL[,10] - dL[,9],
                    diff_11 = dL[,11] - dL[,10],
                    diff_12 = dL[,12] - dL[,11])
  
  tas_11 <- (rowMeans(cbind(
                       read.table(list.files(download_location, full.names = T, recursive = T, pattern = paste0("tasmin_X", year_min - 1, "_11")))[row_indices,1],
                       read.table(list.files(download_location, full.names = T, recursive = T, pattern = paste0("tasmax_X", year_min - 1, "_11")))[row_indices,1]
                       ))) - 273.15
  pr_11 <-  (read.table(list.files(download_location, full.names = T, recursive = T, pattern = paste0("pr_X", year_min - 1, "_11")))[row_indices,1] * 86400 * 30.4)
  
  tas_12 <- (rowMeans(cbind(
    read.table(list.files(download_location, full.names = T, recursive = T, pattern = paste0("tasmin_X", year_min - 1, "_12")))[row_indices,1],
    read.table(list.files(download_location, full.names = T, recursive = T, pattern = paste0("tasmax_X", year_min - 1, "_12")))[row_indices,1]
  ))) - 273.15
  pr_12 <-  (read.table(list.files(download_location, full.names = T, recursive = T, pattern = paste0("pr_X", year_min - 1, "_12")))[row_indices,1] * 86400 * 30.4)
  
  # Here calculate if a month produces food (T) or was dry (F)
  wet_2 <- ifelse(pr_11 < (2*tas_11), F, T)
  wet_1 <- ifelse(pr_12 < (2*tas_12), F, T)
  
  breed_df <- read.table(row_col_file)[row_indices,c("V3", "V4")]
  dry_df <- read.table(row_col_file)[row_indices,c("V3", "V4")]
  
  colnames(breed_df) <- c("col", "row")
  colnames(dry_df) <- c("col", "row")
  
  b <- rep(0, length(dry_df[,1]))
  
  
  rm(tas_11, pr_11, tas_12, pr_12)
  gc()
  
  
  # Do the actual calculations
  
  for(yr in c(year_min:year_max)) {
    
    for(m in c(1:12)) {
      
      tasmin_file <- list.files(download_location, full.names = T, recursive = T, pattern = paste("tasmin", paste0("X",yr), sprintf("%02d", m), sep = "_"))
      tasmax_file <- list.files(download_location, full.names = T, recursive = T, pattern = paste("tasmin", paste0("X", yr), sprintf("%02d", m), sep = "_"))
      pr_file <- list.files(download_location, full.names = T, recursive = T, pattern = paste("pr", paste0("X", yr), sprintf("%02d", m), sep = "_"))
      if ((length(tasmin_file) != 1) | (length(pr_file) != 1)) {
      print(tasmin_file)
      print(pr_file)
      stop("multiple tas or pr files found for specific month/year")

}
      
      tas <- (rowMeans(cbind(read.table(tasmin_file)[row_indices,1], read.table(tasmax_file)[row_indices,1]))) - 273.15
      pr <-  (read.table(pr_file)[row_indices,1]* 86400 * 30.4)
      
      D <- dL[,m]
      delta <- ddL[,m]
      
      W <- ifelse(wet_1 | wet_2, -1.592, 0)
      
      b <- b+1
      b[which(W == F)] <- 0
      
      a <- ifelse(P_B(Temp = tas, D = D, delta = delta, W = W) >= 0.5, 1, 0)
      
      breed_df <- cbind(breed_df, a)
      dry_df <- cbind(dry_df, b)
      
      wet_2 <- wet_1
      wet_1 <- ifelse(pr < (2*tas), F, T)
      
      gc()
    }
    
   }
  
  breeding_file <- file.path(download_location, paste("breeding_months", download_location, year_min, year_max, "chunk", min(row_indices), max(row_indices), '.txt', sep = "_"))
  dry_months_file <- file.path(download_location, paste("consecutive_dry_months", download_location, year_min, year_max, "chunk", min(row_indices), max(row_indices), '.txt', sep = "_"))

 
  write.table(breed_df, breeding_file, quote = F, row.names = F)
  write.table(dry_df, dry_months_file, quote = F, row.names = F)
  
}


# Get arguments from command line
args <- commandArgs(trailingOnly = TRUE)

array_id <- as.integer(args[1])
total_arrays <- as.integer(args[2])

download_location <- sub("/$", "", args[3])
year_min <- as.integer(args[4])
year_max <- as.integer(args[5])

if (args[6] == "peninsula") {
  coord_file = "data/coordinates_peninsula_500_EPSG4326.txt" 
  row_col_file = "data/coordinates_peninsula_500_EPSG3035.txt"
} else if (args[6] == "donana") {
  coord_file = "data/coordinates_donana_500_EPSG4326.txt" 
  row_col_file = "data/coordinates_donana_500_EPSG3035.txt"
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
                 row_col_file = row_col_file,
                 row_indices = row_indices)




