import os
from python.download_his_climate_functions import download_point_climate_value


os.environ["R_HOME"] =  "C:\Program Files\R\R-4.5.1"  
import rpy2.robjects as robjects


# ========================================================================
# Download historical climate Donana CHELSA
# ========================================================================
 
input_coord = "data/pre_processed_data/coordinates_donana_500_EPSG4326.txt"
wget_file = "data/historical_climate_wget_files.txt"
base_download_location = "data/pre_processed_data/Climate_Donana_500"    

# Ensure the download location exists
os.makedirs(base_download_location, exist_ok=True)
 
# Download current climate data if requested
print(f"Downloading current climate data from {wget_file}")
current_download_location = os.path.join(base_download_location, "historical_climate")
download_point_climate_value(
         input_coord, 
         wget_file, 
         current_download_location
)

# ========================================================================
# Download historical climate Peninsula CHELSA
# ========================================================================
 
input_coord = "data/pre_processed_data/coordinates_peninsula_500_EPSG4326.txt"
wget_file = "data/historical_climate_wget_files.txt"
base_download_location = "data/pre_processed_data/Climate_Peninsula_500"
 
 
# Ensure the download location exists
os.makedirs(base_download_location, exist_ok=True)
 
# Download current climate data if requested
print(f"Downloading current climate data from {wget_file}")
current_download_location = os.path.join(base_download_location, "historical_climate")
download_point_climate_value(
         input_coord, 
         wget_file, 
         current_download_location
)



# ================================================================================================================================================
# Format downloaded climate for both downloaded CHELSA values and from WorldClim files already downloaded
# ================================================================================================================================================
 
robjects.r.source('R/Format_historical_climate_rabbit.R')




























