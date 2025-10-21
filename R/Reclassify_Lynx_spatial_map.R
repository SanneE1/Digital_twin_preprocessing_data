library(raster)
library(ncdf4)
library(terra)

# CORINE
corine_raster_path <- "data/original_data/U2018_CLC2018_V2020_20u1.tif"  # Replace with the path to your CORINE raster

# Load the CORINE raster
corine_raster <- rast(corine_raster_path)

# Define the boundaries and crop the CORINE to size
peninsula <- crop(corine_raster, ext(2574200, 3801100, 1515200, 2497800))
Donana <- crop(corine_raster, ext(2800000, 2890000, 1678000, 1750000))

# plot(Donana)

# --------------------------------------
# HABITAT MAP
# --------------------------------------

# Reclassification table --- Based on Revilla 2015 (both options)
reclass_Rev1 <- as.matrix(data.frame(
  old = c(1:44, 48),
  new = c(rep(0,9), rep(1,13),2,2,2,1,2,2,2,rep(1,4),0,0,1, rep(0,9))
))

reclass_Rev2 <- as.matrix(data.frame(
  old = c(1:44, 48),
  new = c(rep(0,9), rep(1,12),2,2,2,2,1,2,2,2,rep(1,4),0,0,1, rep(0,9))
))

# Perform the reclassification
# Convert the reclass_table into a matrix for terra::classify
reclas_peninsula1 <- classify(peninsula, reclass_Rev1)
reclas_donana1 <- classify(Donana, reclass_Rev1)

reclas_peninsula2 <- classify(peninsula, reclass_Rev2)
reclas_donana2 <- classify(Donana, reclass_Rev2)

print("Resizing to 500x500m resolution...")
# Create template rasters with 500m resolution
peninsula_template <- rast(
  xmin = xmin(reclas_peninsula1), 
  xmax = xmax(reclas_peninsula1),
  ymin = ymin(reclas_peninsula1), 
  ymax = ymax(reclas_peninsula1),
  resolution = c(500, 500),
  crs = crs(reclas_peninsula1)
)

donana_template <- rast(
  xmin = xmin(reclas_donana1), 
  xmax = xmax(reclas_donana1),
  ymin = ymin(reclas_donana1), 
  ymax = ymax(reclas_donana1),
  resolution = c(500, 500),
  crs = crs(reclas_donana1)
)

# Resample instead of project
reproj_peninsula1 <- resample(reclas_peninsula1, peninsula_template, method = "mode")
reproj_peninsula2 <- resample(reclas_peninsula2, peninsula_template, method = "mode")

reproj_donana1 <- resample(reclas_donana1, donana_template, method = "mode")
reproj_donana2 <- resample(reclas_donana2, donana_template, method = "mode")


# Save raster maps as asc (easiest to change into format needed for pascal program)
writeRaster(reproj_peninsula1, file.path(output_dir, "Lynx_HabitatMap_500_Peninsula_Revilla_2015_1.asc"), datatype = "INT2S", overwrite = TRUE)
writeRaster(reproj_donana1, file.path(output_dir, "Lynx_HabitatMap_500_Donana_Revilla_2015_1.asc"), datatype = "INT2S", overwrite = TRUE)

writeRaster(reproj_peninsula2, file.path(output_dir, "Lynx_HabitatMap_500_Peninsula_Revilla_2015_2.asc"), datatype = "INT2S", overwrite = TRUE)
writeRaster(reproj_donana2, file.path(output_dir, "Lynx_HabitatMap_500_Donana_Revilla_2015_2.asc"), datatype = "INT2S", overwrite = TRUE)



# --------------------------------------
# BREEDING HABITAT   -- Carryover from the stand-alone Lynx model. Keeping it here, because I would like to have a comparison at some point between using rabbits or this!
# --------------------------------------
# 
# 
# # Reclassification table --- Based on Revilla 2015 (both options)
# reclass_Ford <- as.matrix(data.frame(
#   old = c(1:44, 48),
#   new = c(rep(0,27), 1, 1, rep(0,16))
# ))
# 
# 
# # Perform the reclassification
# # Convert the reclass_table into a matrix for terra::classify
# reclas_peninsulaF <- classify(peninsula, reclass_Ford)
# reclas_donanaF <- classify(Donana, reclass_Ford)
# 
# 
# # Resize to 500x500m raster size
# reproj_peninsulaF <- resample(reclas_peninsulaF, peninsula_template, method = "mode")
# reproj_donanaF <- resample(reclas_donanaF, donana_template, method = "mode")
# 
# 
# # Save raster maps as asc (easiest to change into format needed for pascal program)
# writeRaster(reproj_peninsulaF, file.path(output_dir, "Lynx_BreedingHabitat_500_Peninsula_Fordham_2013.asc"), datatype = "INT2S", overwrite = TRUE)
# writeRaster(reproj_donanaF, file.path(output_dir, "Lynx_BreedingHabitat_500_Donana_Fordham_2013.asc"), datatype = "INT2S", overwrite = TRUE)
# 
#
# --------------------------------------
# POPULATION MAPS
# --------------------------------------

# Extract Iberian lynx populations for IUCN file
full_map <- vect(iucn_terrestrial_mammals)
iucn_lynx <- full_map[full_map$sci_name=='Lynx pardinus',]
iucn_lynx <- project(iucn_lynx, crs(peninsula))#, method="pipeline")
iucn_lynx <- iucn_lynx[order(iucn_lynx$SHAPE_Area),]

# Area's according to the shape file
# 1 Sierra  0.137
# 2 Donana   0.060
# 3 Montes   0.056
# 4 Vale    0.046
# 5 Matachel 0.0315

iucn_lynx$subpop_int <- c(4, 3, 5, 4, 3, 2, 1, 1)

# Rasterize populations
iucn_peninsula <- terra::crop(iucn_lynx, ext(peninsula))
iucn_peninsula <- terra::rasterize(iucn_peninsula, peninsula, field = "subpop_int")

iucn_donana <- terra::crop(iucn_lynx, ext(Donana))
iucn_donana <- terra::rasterize(iucn_donana, Donana, field = "subpop_int")

# plot(iucn_peninsula)
# plot(iucn_donana)

# Resize to 500x500m raster size
reproj_iucnPeninsula <- resample(iucn_peninsula, peninsula_template, method = "mode")
reproj_iucnDonana <- resample(iucn_donana, donana_template, method = "mode")


# Save raster maps as asc (easiest to change into format needed for pascal program)
writeRaster(reproj_iucnPeninsula, file.path(output_dir, "Lynx_populations_500_Peninsula_IUCN.asc"), datatype = "INT2S", overwrite = TRUE)
writeRaster(reproj_iucnDonana, file.path(output_dir, "Lynx_populations_500_Donana_IUCN.asc"), datatype = "INT2S", overwrite = TRUE)


# Increase the iucn population area's a bit -----------------------------------------------------------------------------------------

# lynx_2 <- terra::buffer(iucn_lynx, width = 2000)
# lynx_6 <- terra::buffer(iucn_lynx, width = 6000)
lynx_75 <- terra::buffer(iucn_lynx, width = 7500)

# plot(iucn_lynx)
# plot(lynx_2)
# plot(lynx_6)
# plot(lynx_75)

# Rasterize populations for the 7.5 buffer 
iucn_peninsula75 <- terra::crop(lynx_75, ext(peninsula))
iucn_donana75 <- terra::crop(lynx_75, ext(Donana))

# Re-number populations to get seperate numbers for non-overlapping polygons
proximity_threshold <- 10  # distance in map units
aggregated <- terra::aggregate(iucn_peninsula75)

disaggregated <- terra::disagg(aggregated)

centroids <- terra::centroids(disaggregated)
coords <- terra::crds(centroids)
poly_data <- data.frame(
  id = 1:nrow(disaggregated),
  x = coords[,1],
  y = coords[,2]
)

sorted_indices <- order(poly_data$x)

new_integer_ids <- numeric(nrow(disaggregated))
for (i in 1:length(sorted_indices)) {
  new_integer_ids[sorted_indices[i]] <- i
}
disaggregated$new_id <- new_integer_ids


# Rasterize
iucn_peninsula75 <- terra::rasterize(disaggregated, peninsula, field = "new_id")
iucn_donana75 <- terra::rasterize(iucn_donana75, Donana, field = "subpop_int")


# Resize to 500x500m raster size
reproj_peninsula_lynx75 <- resample(iucn_peninsula75, peninsula_template, method = "mode")
reproj_donana_lynx75 <- resample(iucn_donana75, donana_template, method = "mode")


# Save raster maps as asc (easiest to change into format needed for pascal program)
writeRaster(reproj_peninsula_lynx75, file.path(output_dir, "Lynx_populations_500_Peninsula_IUCN75.asc"), datatype = "INT2S", overwrite = TRUE)
writeRaster(reproj_donana_lynx75, file.path(output_dir, "Lynx_populations_500_Donana_IUCN75.asc"), datatype = "INT2S", overwrite = TRUE)


# ----------------------------------------------------------------------------
# Calculate dropping point for populations
# ----------------------------------------------------------------------------

# Peninsula

# Sort of central coordinates in Breeding habitat per population
# 1 Sierra   3097665 1794236
# 2 Donana   2847165 1713702
# 3 Montes   3077997 1969615
# 4 Vale     2755812 1800951
# 5 Matachel 2923345 1862098

# colFromX(reproj_iucnPeninsula, x = c(3097665, 2847165, 3077997, 2755812, 2923345))
# rowFromY(reproj_iucnPeninsula, y = c(1794236, 1713702, 1969615, 1800951, 1862098))

# colFromX(reproj_iucnDonana, x = c(2847165))
# rowFromY(reproj_iucnDonana, y = c(1713702))

# ----------------------------------------------------------------------------
# Future land cover LANDMADE 
# ----------------------------------------------------------------------------
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
    "barrier" = c(12, 15),
    "matrix" = c(9:11, 13, 14, 16),
    "dispersal" = c(1:8))
  
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
    
    
    writeRaster(peninsula, file.path(output_folder, "peninsula", model, paste0("Lynx_HabitatMap_", current_year, ".asc")), 
                datatype = "INT2S", overwrite = TRUE, NAflag = 0)
    writeRaster(Donana, file.path(output_folder, "donana", model, paste0("Lynx_HabitatMap_", current_year, ".asc")), 
                datatype = "INT2S", overwrite = TRUE, NAflag = 0)
    
  }
}





