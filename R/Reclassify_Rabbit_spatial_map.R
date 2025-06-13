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
output_files <- list( peninsula = file.path(output_folder, "HabitatMap_500_Peninsula_Fordham_2013.asc"),
                      donana = file.path(output_folder, "HabitatMap_500_Donana_Fordham_2013.asc"))
                  
print("save files")

writeRaster(reproj_peninsula, output_files$peninsula, datatype = "INT2S", overwrite = TRUE, NAflag = -9999)
writeRaster(reproj_donana, output_files$donana, datatype = "INT2S", overwrite = TRUE, NAflag = -9999)


