setwd("~/01_Natura_Connect/01_Rabbit_workflow")

library(dplyr)
library(terra)

csvToRaster <- function(fileName, habitat_raster, return_df = F, plot = T, 
                        save_tiff = F, tiff_name = NA) {
  
  mat_status <- as.matrix(read.csv(fileName, header = F))
  
  df <- terra::rasterize(mat_status, habitat_raster)
  values(df) <- mat_status
 
  if (return_df) {
    return(df)  
  } 
  
  if (plot) {
    plot(df)
  }
  
  if(save_tiff) {
    writeRaster(df, tiff_name, overwrite = T)
  }
  
}

rast_habitat <- rast("data/pre_processed_data/HabitatMap_500_Donana_Fordham_2013.asc")

map_files <- list.files("../00_Rabbit_model/rabbit_donana/output_data/", full.names = T, pattern = "distribution", ignore.case = T)
map_names <- list.files("../00_Rabbit_model/rabbit_donana/output_data/", pattern = "distribution", ignore.case = T)


for (i in c(1:length(map_files))) {
  csvToRaster(map_files[i], 
              rast_habitat, save_tiff = T, 
              tiff_name = paste0("Results/maps/", gsub(".csv", "", map_names[i]), ".tiff" ))
}




