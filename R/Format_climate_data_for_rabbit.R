
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

calculate_BM_cDM <- function(download_location, 
                             coord_file, 
                             year_min = 2002, 
                             year_max = 2018,
                             result_dir,
                             temperature_type = c("mean", "minmax")) {
  
  if (!dir.exists(result_dir)) {dir.create(result_dir)}
  
  # Full file of tas/pr per cell
  files <- list.files(download_location, full.names = TRUE, recursive = TRUE)
  
  # Check time range for which we have both rain and temperature information
  files_pr <- list.files(download_location, full.names = TRUE, recursive = TRUE, pattern = "pr")
  
  if (temperature_type == "mean") {
    files_tas <- list.files(download_location, full.names = TRUE, recursive = TRUE, pattern = "tas")
    tas_time <- stringr::str_extract(files_tas, '_\\d{2}_\\d{4}_')
    pr_time <- stringr::str_extract(files_pr, '_\\d{2}_\\d{4}_')
  } else {
    files_tasmax <- list.files(download_location, full.names = TRUE, recursive = TRUE, pattern = "tasmax")
    files_tasmin <- list.files(download_location, full.names = TRUE, recursive = TRUE, pattern = "tasmin")
    tas_time <- stringr::str_extract(files_tasmax, '\\d{4}_\\d{2}_')
    pr_time <- stringr::str_extract(files_pr, '\\d{4}_\\d{2}_')
  }
  
  # Check for mismatches
  tas_time[which(!(tas_time %in% pr_time))]
  pr_time[which(!(pr_time %in% tas_time))]
  
  # Define breeding probability function
  P_B <- function(Temp, D, delta, W) {
    1 / (1 + exp(4.542 - (0.605 * Temp) + (0.029 * Temp^2) - (0.006 * D) - (0.017 * delta) - W))
  }
  
  # Daylength calculations
  mL <- c(31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
  mE <- cumsum(mL)
  
  dL <- lapply(as.list(c(1:12)), function(x) {
    read.table(coord_file)[row_indices, c("V1", "V2")] %>% 
      as.data.frame() %>%
      rowwise() %>%
      mutate(dayL = mean(daylength(V2, c((mE[x] - mL[x]):mE[x])) * 60),
             .keep = "none")
  }) %>% bind_cols()
  
  # Calculate delta (day length differences)
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
  
  # Load initial data for wet/dry calculations (November and December of previous year)
  if (temperature_type == "mean") {
    tas_11 <- (read.table(list.files(download_location, full.names = TRUE, recursive = TRUE, 
                                     pattern = paste0("tas_11_", year_min - 1)))[row_indices, 1] / 10) - 273.15
    pr_11 <- read.table(list.files(download_location, full.names = TRUE, recursive = TRUE, 
                                   pattern = paste0("pr_11_", year_min - 1)))[row_indices, 1] / 100
    
    tas_12 <- (read.table(list.files(download_location, full.names = TRUE, recursive = TRUE, 
                                     pattern = paste0("tas_12_", year_min - 1)))[row_indices, 1] / 10) - 273.15
    pr_12 <- read.table(list.files(download_location, full.names = TRUE, recursive = TRUE, 
                                   pattern = paste0("pr_12_", year_min - 1)))[row_indices, 1] / 100
  } else {
    tas_11 <- (rowMeans(cbind(
      read.table(list.files(download_location, full.names = TRUE, recursive = TRUE, 
                            pattern = paste0("tasmin_X", year_min - 1, "_11")))[row_indices, 1],
      read.table(list.files(download_location, full.names = TRUE, recursive = TRUE, 
                            pattern = paste0("tasmax_X", year_min - 1, "_11")))[row_indices, 1]
    ))) - 273.15
    pr_11 <- (read.table(list.files(download_location, full.names = TRUE, recursive = TRUE, 
                                    pattern = paste0("pr_X", year_min - 1, "_11")))[row_indices, 1] * 86400 * 30.4)
    
    tas_12 <- (rowMeans(cbind(
      read.table(list.files(download_location, full.names = TRUE, recursive = TRUE, 
                            pattern = paste0("tasmin_X", year_min - 1, "_12")))[row_indices, 1],
      read.table(list.files(download_location, full.names = TRUE, recursive = TRUE, 
                            pattern = paste0("tasmax_X", year_min - 1, "_12")))[row_indices, 1]
    ))) - 273.15
    pr_12 <- (read.table(list.files(download_location, full.names = TRUE, recursive = TRUE, 
                                    pattern = paste0("pr_X", year_min - 1, "_12")))[row_indices, 1] * 86400 * 30.4)
  }
  
  # Calculate initial wet/dry conditions
  wet_2 <- ifelse(pr_11 < (2 * tas_11), FALSE, TRUE)
  wet_1 <- ifelse(pr_12 < (2 * tas_12), FALSE, TRUE)
  
  # Initialize result data frames
  breed_df_empty <- read.table(coord_file)[row_indices, c("V3", "V4")]
  dry_df_empty <- read.table(coord_file)[row_indices, c("V3", "V4")]
  
  colnames(breed_df_empty) <- c("col", "row")
  colnames(dry_df_empty) <- c("col", "row")
  
  breed_df <- breed_df_empty
  dry_df <- dry_df_empty
  
  b <- rep(0, length(dry_df[, 1]))
  
  # Clean up temporary variables
  rm(tas_11, pr_11, tas_12, pr_12)
  gc()
  
  # Main calculation loop
  for (yr in year_min:year_max) {
    for (m in 1:12) {
      
      # Load temperature and precipitation data based on type
      if (temperature_type == "mean") {
        tas_file <- list.files(download_location, full.names = TRUE, recursive = TRUE, 
                               pattern = paste("tas", sprintf("%02d", m), yr, sep = "_"))
        pr_file <- list.files(download_location, full.names = TRUE, recursive = TRUE, 
                              pattern = paste("pr", sprintf("%02d", m), yr, sep = "_"))
        
        if ((length(tas_file) != 1) | (length(pr_file) != 1)) {
          stop("Multiple tas or pr files found for specific month/year")
        }
        
        tas <- (read.table(tas_file)[row_indices, 1] / 10) - 273.15
        pr <- read.table(pr_file)[row_indices, 1] / 100
        
      } else {
        tasmin_file <- list.files(download_location, full.names = TRUE, recursive = TRUE, 
                                  pattern = paste("tasmin", paste0("X", yr), sprintf("%02d", m), sep = "_"))
        tasmax_file <- list.files(download_location, full.names = TRUE, recursive = TRUE, 
                                  pattern = paste("tasmax", paste0("X", yr), sprintf("%02d", m), sep = "_"))
        pr_file <- list.files(download_location, full.names = TRUE, recursive = TRUE, 
                              pattern = paste("pr", paste0("X", yr), sprintf("%02d", m), sep = "_"))
        
        if ((length(tasmin_file) != 1) | (length(tasmax_file) != 1) | (length(pr_file) != 1)) {
          print(paste("tasmin_file:", tasmin_file))
          print(paste("tasmax_file:", tasmax_file))
          print(paste("pr_file:", pr_file))
          stop("Multiple or missing temperature/precipitation files found for specific month/year")
        }
        
        tas <- (rowMeans(cbind(read.table(tasmin_file)[row_indices, 1], 
                               read.table(tasmax_file)[row_indices, 1]))) - 273.15
        pr <- (read.table(pr_file)[row_indices, 1] * 86400 * 30.4)
      }
      
      # Get day length and delta for current month
      D <- dL[, m]
      delta <- ddL[, m]
      
      # Calculate W parameter
      W <- ifelse(wet_1 | wet_2, -1.592, 0)
      
      # Update consecutive dry months counter
      b <- b + 1
      b[which(W == FALSE)] <- 0
      
      # Calculate breeding probability
      a <- ifelse(P_B(Temp = tas, D = D, delta = delta, W = W) >= 0.5, 1, 0)
      
      # Add results to data frames
      breed_df <- cbind(breed_df, a)
      dry_df <- cbind(dry_df, b)
      
      # Update wet conditions for next iteration
      wet_2 <- wet_1
      wet_1 <- ifelse(pr < (2 * tas), FALSE, TRUE)
      
      gc()
    }
    
    colnames(breed_df)[c(3:14)] <- c(1:12)
    colnames(dry_df)[c(3:14)] <- c(1:12)
    
    breeding_file <- file.path(result_dir, 
                               paste0("breeding_months_", yr, '.txt'))
    dry_months_file <- file.path(result_dir, 
                                 paste0("consecutive_dry_months_", yr, '.txt'))
    
    # Write results
    write.table(breed_df, breeding_file, quote = FALSE, row.names = FALSE)
    write.table(dry_df, dry_months_file, quote = FALSE, row.names = FALSE)
    
    breed_df <- breed_df_empty
    dry_df <- dry_df_empty
    
    gc()
    
  }
  
  
  
}