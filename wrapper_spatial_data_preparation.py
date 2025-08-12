import os
from python.transform_asc_to_input_txt_map import process_folder
from python.get_matrix_cell_coordinates import extract_and_transform_coordinates

os.environ["R_HOME"] =  "C:/Users/Z1512834Z/AppData/Local/Programs/R/R-4.4.0"  
import rpy2.robjects as robjects

# Set variables
output_dir = os.path.join("data", "pre_processed_data")
txt_dir = os.path.join("input_data", "maps")

robjects.r.assign("corine_raster_path", "data/original_data/U2018_CLC2018_V2020_20u1.tif")
robjects.r.assign("output_dir", output_dir)
robjects.r.assign("iucn_terrestrial_mammals", "data/original_data/IUCN/MAMMALS_TERRESTRIAL_ONLY.shp")


# HABITAT CLASSIFICATION ---------------------------------------------------------------------------------------
robjects.r.source('R/Reclassify_Rabbit_spatial_map.R')
robjects.r.source('R/Reclassify_Lynx_spatial_map.R')

# ASC TO TXT CONVERTER for maps --------------------------------------------------------------------------------
process_folder(output_dir, txt_dir)

# GET CELL CENTER COORDINATES ----------------------------------------------------------------------------------
rast_file_peninsula = os.path.join(output_dir, "Rabbit_HabitatMap_500_Peninsula_Fordham_2013.asc")
rast_file_donana = os.path.join(output_dir, "Rabbit_HabitatMap_500_Donana_Fordham_2013.asc")
output_donana = os.path.join(output_dir, "coordinates_donana_500_EPSG4326.txt")
output_peninsula = os.path.join(output_dir, "coordinates_peninsula_500_EPSG4326.txt")

extract_and_transform_coordinates(rast_file_donana, output_donana)
extract_and_transform_coordinates(rast_file_peninsula, output_peninsula)








