import os
import subprocess

os.environ["R_HOME"] =  "C:/Users/Z1512834Z/AppData/Local/Programs/R/R-4.4.0"  

import rpy2.robjects as robjects

# Check later if this is still needed
# os.environ['PROJ_LIB'] = "C:/Users/Z1512834Z/AppData/Local/Programs/R/R-4.4.0/library/sf/proj"  # Path to R's PROJ files, not Anaconda's

# Reclassify CORINE map for rabbit suitability - for some reason the robjects.r.source() doesn't work here, but subprocess works just fine!
robjects.r.source('R/Reclassify_Rabbit_spatial_map.R')

# Change maps to input format needed for model
subprocess.run(["python", "python/transform_asc_to_input_txt_map.py"],
               capture_output=True)

# Get coordinates of cells in the map
subprocess.run(['Rscript', 'R/Calculate_coordinates_of_matrix.R'])

# Download CHELSA data for coordinates
subprocess.run(["python", "python/download_historical_climate.py"])

# Formatting downloaded climate
robjects.r.source('R/Formatting_historical_climate_data.R')

