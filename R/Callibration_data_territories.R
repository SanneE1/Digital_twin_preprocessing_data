library(terra)
library(dplyr)


# Annual distribution maps

files <- list.files("data/original_data/Annual_distribution_Alejandro/", pattern = "distribution.shp$", full.names = T)
years <- regmatches(files, gregexpr("\\d{4}", files))

hab_file <- "data/pre_processed_data/Lynx_HabitatMap_500_Peninsula_Revilla_2015_1.asc"
hab_rast <- rast(hab_file)

if(!(dir.exists("observation_data/annual_distribution_matrices/"))) {dir.create("observation_data/annual_distribution_matrices/", recursive = T)}

for(i in c(1:length(files))){
file = files[[i]]
dist <- vect(file)
dist <- project(dist, crs(hab_rast))

obs_rast <- terra::rasterize(dist, hab_rast, background = 0)
obs_rast <- mask(obs_rast, hab_rast)

obs_mat <- as.matrix(obs_rast, wide = T)

write.csv(obs_mat, row.names = F, col.names = F, 
          file = file.path("observation_data", "annual_distribution_matrices", paste0("distribution_", years[i], ".csv")))
}




# Territory files
files <- list.files("data/original_data/20250825_data_German/Territorios/", pattern = ".shp$", 
                    recursive = T, full.names = T)

years <- regmatches(files, gregexpr("\\d{4}", files))
years <- sort(as.numeric(unique(sapply(years, last))))

vect_list <- list()

for (yr in years) {
  year_files <- grep(yr, files, value = T)
  
  if (length(year_files) == 1) {
    vect_list[[as.character(yr)]] <- vect(year_files)
  } else {
    a <- vect(year_files[1])
    for (i in c(2:length(year_files))) {
      a <- rbind(a, vect(year_files[i]))
    }
    vect_list[[as.character(yr)]] <- a
  }
  
}





