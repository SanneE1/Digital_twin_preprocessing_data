#user_lib <- file.path(Sys.getenv("HOME"), "R", "win-library", "4.4")

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

calculate_BM_cDM <- function(download_location, result_file_breeding, result_file_dry_months,
                             coord_file, row_col_file) {
  
  # Full file of tas/pr per cell
  files <- list.files(download_location, full.names = T, recursive = T)
  
  # Check time rage for which we have both rain and temperature information
  files_pr <- list.files(download_location, full.names = T, recursive = T, pattern = "pr")
  files_tas <- list.files(download_location, full.names = T, recursive = T, pattern = "tas")
  
  tas_time <- stringr::str_extract(files_tas, '_\\d{2}_\\d{4}_')
  pr_time <- stringr::str_extract(files_pr, '_\\d{2}_\\d{4}_')
  
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
    read.table(coord_file) %>% 
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
  
  tas_11_2001 <- (read.table(list.files(download_location, full.names = T, recursive = T, pattern = "tas_11_2001"))[,1]/10) - 273.15
  pr_11_2001 <-  read.table(list.files(download_location, full.names = T, recursive = T, pattern = "pr_11_2001"))[,1] / 100
  
  tas_12_2001 <- (read.table(list.files(download_location, full.names = T, recursive = T, pattern = "tas_12_2001"))[,1]/10) - 273.15
  pr_12_2001 <-  read.table(list.files(download_location, full.names = T, recursive = T, pattern = "pr_12_2001"))[,1] / 100
  
  # Here calculate if a month produces food (T) or was dry (F)
  wet_2 <- ifelse(pr_11_2001 < (2*tas_11_2001), F, T)
  wet_1 <- ifelse(pr_12_2001 < (2*tas_12_2001), F, T)
  
  breed_df <- read.table(row_col_file)[,c("V3", "V4")]
  dry_df <- read.table(row_col_file)[,c("V3", "V4")]
  
  colnames(breed_df) <- c("col", "row")
  colnames(dry_df) <- c("col", "row")
  
  b <- rep(0, length(dry_df[,1]))
  
  
  rm(tas_11_2001, pr_11_2001, tas_12_2001, pr_12_2001)
  gc()
  
  
  # Do the actual calculations
  
  for(yr in c(2002:2018)) {
    
    for(m in c(1:12)) {
      
      tas_file <- list.files(download_location, full.names = T, recursive = T, pattern = paste("tas", sprintf("%02d", m), yr, sep = "_"))
      pr_file <- list.files(download_location, full.names = T, recursive = T, pattern = paste("pr", sprintf("%02d", m), yr, sep = "_"))
      if ((length(tas_file) != 1) | (length(pr_file) != 1)) {stop("multiple tas or pr files found for specific month/year")}
      
      tas <- (read.table(tas_file)[,1]/10) - 273.15
      pr <-  read.table(pr_file)[,1]/100
      
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
  
  write.table(breed_df, result_file_breeding, quote = F, row.names = F)
  write.table(dry_df, result_file_dry_months, quote = F, row.names = F)
  
  
}


calculate_BM_cDM(download_location = "data/pre_processed_data/Climate_Donana_500/",
                result_file_breeding = "input_data/breeding_months_donana_historic_2002_2018.txt",
                result_file_dry_months = "input_data/consecutive_dry_months_donana_historic_2002_2018.txt",
                coord_file = "data/pre_processed_data/coordinates_donana_500_EPSG4326.txt",
                row_col_file = "data/pre_processed_data/coordinates_donana_500_EPSG3035.txt")



# calculate_BM_cDM(download_location = "data/pre_processed_data/Climate_Peninsula_500/", 
#                  result_file_breeding = "data/pre_processed_data/breeding_months_peninsula_historic_2002_2018.txt", 
#                  result_file_dry_months = "data/pre_processed_data/consecutive_dry_peninsula_historic_2002_2018.txt", 
#                  coord_file = "data/pre_processed_data/coordinates_peninsula_500_EPSG4326.txt", 
#                  row_col_file = "data/pre_processed_data/coordinates_peninsula_500_EPSG3035.txt")





