# Load required libraries
library(raster)
library(ncdf4)
library(terra)

corine_raster_path = "data/original_data/U2018_CLC2018_V2020_20u1.tif"
output_folder = "data/pre_processed_data/" 

# Load the CORINE raster
corine_raster <- rast(corine_raster_path)

# Define the boundaries and crop the CORINE to size
peninsula <- crop(corine_raster, ext(2574200, 3801100, 1515200, 2497800))
Donana <- crop(corine_raster, ext(2800000, 2890000, 1678000, 1750000))

# Reclassification table --- Based on Fordham 2013 Table S3
reclass_mat <- as.matrix(data.frame(
  old = c(1:44, 48),
  new = c(rep(0,9), 1, 0,1,0,0, 1,1,1,2,1,1,1,1,0,0,1,2,1,1,2,1,0,2,1,rep(0,12))
))

# Perform the reclassification
# Convert the reclass_table into a matrix for terra::classify
print("reclassify")

reclas_peninsula <- classify(peninsula, reclass_mat)
reclas_donana <- classify(Donana, reclass_mat)

# Resize to 500x500m raster size
print("resize")
# reproj_peninsula <- project(reclas_peninsula, y = "EPSG:3035",       
#                              res = c(500,500),     # Target resolution
#                              method = "mode",      # Resampling method (mode for categorical data)
#                              NAflag = -9999, 
#                             align = T,        
# )
# 
# reproj_donana <- project(reclas_donana, y = "EPSG:3035",       
#                             res = c(500,500),     # Target resolution
#                             method = "mode",      # Resampling method (mode for categorical data)
#                             NAflag = -9999, 
#                          align = T,        
# )

# Resize to 500x500m WITHOUT using project()
print("Resizing to 500x500m resolution...")

# Create template rasters with 500m resolution
peninsula_template <- rast(
  xmin = xmin(reclas_peninsula), 
  xmax = xmax(reclas_peninsula),
  ymin = ymin(reclas_peninsula), 
  ymax = ymax(reclas_peninsula),
  resolution = c(500, 500),
  crs = crs(reclas_peninsula)
)

donana_template <- rast(
  xmin = xmin(reclas_donana), 
  xmax = xmax(reclas_donana),
  ymin = ymin(reclas_donana), 
  ymax = ymax(reclas_donana),
  resolution = c(500, 500),
  crs = crs(reclas_donana)
)

# Resample instead of project
reproj_peninsula <- resample(reclas_peninsula, peninsula_template, method = "mode")
reproj_donana <- resample(reclas_donana, donana_template, method = "mode")

# Set the output data type to Int16
output_files <- list( peninsula = file.path(output_folder, "Rabbit_HabitatMap_500_Peninsula_Fordham_2013.asc"),
                      donana = file.path(output_folder, "Rabbit_HabitatMap_500_Donana_Fordham_2013.asc"))

print("save files")

writeRaster(reproj_peninsula, output_files$peninsula, datatype = "INT2S", overwrite = TRUE, NAflag = -9999)
writeRaster(reproj_donana, output_files$donana, datatype = "INT2S", overwrite = TRUE, NAflag = -9999)


## Future land cover LANDMADE ----------------------------------------------------------------------------------

landmade_raster_files = list.files("data/original_data/LUC_future_landcover/", full.names = T)
output_folder = "data/pre_processed_data/landmade_future/" 

#go through all files
for (file in landmade_raster_files) {

  print(file)
  # get scenario
  model <- regmatches(file, regexpr("ssp[[:alnum:]]+", file))
  
  # Load nc file
  nc_data <- nc_open(file)
  
  # Reclassification table --- Based on Fordham 2013 Table S3
  reclass_mat <- list(
    "barrier" = c(1:6, 11, 12, 15, 16),
    "matrix" = c(13, 14),
    "dispersal" = c(7:10))
  
  
  lon <- ncvar_get(nc_data, "lon")
  lat <- ncvar_get(nc_data, "lat")
  time_vals <- ncvar_get(nc_data, "time")
  lctype_dim <- nc_data$dim$lctype$len 
  
  time_origin <- as.Date("1950-01-01")
  dates <- time_origin + time_vals
  years <- as.numeric(format(dates, "%Y"))
  
  for(current_year in years){

    landcover_data <- ncvar_get(nc_data, "landCoverFrac", 
                                start = c(1, 1, 1, which(years == current_year)),
                                count = c(-1, -1, -1, 1))
    
    landcover_data_barrier <- rowSums(landcover_data[,, reclass_mat[["barrier"]]], dims = 2)
    landcover_data_matrix <- rowSums(landcover_data[,, reclass_mat[["matrix"]]], dims = 2)
    landcover_data_dispersal <- rowSums(landcover_data[,, reclass_mat[["dispersal"]]], dims = 2)
    
    pmax_mat <- pmax(landcover_data_barrier, landcover_data_matrix, landcover_data_dispersal)
    
    yearly_mat <- ifelse(landcover_data_barrier == pmax_mat, 0, 
                         ifelse(landcover_data_matrix == pmax_mat, 1,
                                ifelse(landcover_data_dispersal == pmax_mat, 2,
                                       999)))
    
    
    yearly_rast <- flip(rast(t(yearly_mat), crs = "EPSG:4326", extent = c(min(lon), max(lon), min(lat), max(lat))), direction = "vertical")
    
    # plot(yearly_rast)
    
    yearly_rast <- project(yearly_rast, crs(corine_raster))
    
    
    # Define the boundaries and crop the CORINE to size
    peninsula  <- resample(yearly_rast, peninsula_template, method = "mode")
    Donana  <- resample(yearly_rast, donana_template, method = "mode")
    
    # plot(peninsula)
    # plot(Donana)
    
    if(!dir.exists(file.path(output_folder, "donana", model))){
      dir.create(file.path(output_folder, "donana", model), recursive = T)
    }
    
    if(!dir.exists(file.path(output_folder, "peninsula", model))){
      dir.create(file.path(output_folder, "peninsula", model), recursive = T)
    }
    
    writeRaster(peninsula, file.path(output_folder, "peninsula", model, paste0("Rabbit_HabitatMap_", current_year, ".asc")), 
                datatype = "INT2S", overwrite = TRUE, NAflag = 0)
    writeRaster(Donana, file.path(output_folder, "donana", model, paste0("Rabbit_HabitatMap_", current_year, ".asc")), 
                datatype = "INT2S", overwrite = TRUE, NAflag = 0)
    
  }
}
