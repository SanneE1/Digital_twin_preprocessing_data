import pandas as pd
from osgeo import gdal
from pathlib import Path
import os
from pyproj import Transformer
import csv
from tqdm import tqdm


def read_wget_urls(wget_file='data/CHELSAwget_files.txt'):
    """Read the CHELSA wget URLs from file"""
    urls = pd.read_csv(wget_file, header=None)[0].tolist()
    # Clean URLs to remove any whitespace
    return [url.strip() for url in urls]

def process_url_to_filename(url):
    """Convert URL to output filename, following the R gsub pattern"""
    return (url.replace('https://os.zhdk.cloud.switch.ch/chelsav2/GLOBAL/monthly/pr/', '')
              .replace('https://os.zhdk.cloud.switch.ch/chelsav2/GLOBAL/monthly/tas/', '')
              .replace('.tif', '_coord.txt'))
        
def read_coordinates(coord_file):
    """Read coordinates from the input file"""
    try:
        coords = pd.read_csv(coord_file, delim_whitespace=True, 
                            names=['Longitude', 'Latitude', 'row', 'col'])
        return coords
    except Exception as e:
        print(f"Error reading coordinates file: {e}")
        return None

def ensure_directory_exists(file_path):
    """Ensure the directory for the given file path exists"""
    directory = os.path.dirname(file_path)
    if directory and not os.path.exists(directory):
        os.makedirs(directory, exist_ok=True)

def extract_values(coords, raster_url, output_file):
    """Extract values from CHELSA raster at given coordinates"""
    try:
        # Clean the URL and construct the vsicurl path
        clean_url = raster_url.strip()
        vsicurl_path = f'/vsicurl/{clean_url}'
        print(f"Attempting to open: {vsicurl_path}")
        
        # Open the remote raster using vsicurl
        ds = gdal.Open(vsicurl_path)
        if ds is None:
            raise ValueError(f"Could not open raster: {vsicurl_path}")

        # Get geotransform
        gt = ds.GetGeoTransform()
        rb = ds.GetRasterBand(1)
        
        values = []
        for _, row in coords.iterrows():
            # Convert geographic coordinates to pixel coordinates
            px = int((row['Longitude'] - gt[0]) / gt[1])
            py = int((row['Latitude'] - gt[3]) / gt[5])
            
            # Read the value
            value = rb.ReadAsArray(px, py, 1, 1)
            if value is not None:
                values.append(str(float(value[0][0])))
            else:
                values.append('NA')
        
        # Ensure the output directory exists
        ensure_directory_exists(output_file)
        
        # Write to output file
        with open(output_file, 'w') as f:
            f.write('\n'.join(values))
            
        print(f"Successfully extracted values to: {output_file}")
        
    except Exception as e:
        print(f"Error processing {raster_url}: {e}")
    finally:
        if ds:
            ds = None  # Close the dataset

def download_point_climate_value(input_coord, wget_file, download_location):
    """Main function to process all CHELSA files"""
    # Convert download_location to Path object and ensure it exists
    download_path = Path(download_location)
    download_path.mkdir(parents=True, exist_ok=True)
    
    # Read and convert coordinates
    coords = read_coordinates(input_coord)
    if coords is None:
        return
    
    # Read URLs
    urls = read_wget_urls(wget_file)
    
    # Process each URL
    for url in urls:
        output_filename = process_url_to_filename(url)
        output_path = download_path / output_filename
        
        extract_values(coords, url, str(output_path))


if __name__ == "__main__":
   
   
    # ========================================================================
    # Parameters set for Donana 
    # ========================================================================
    
    input_coord = "data/pre_processed_data/coordinates_donana_500_EPSG4326.txt"
    base_download_location = "data/pre_processed_data/Climate_Donana_500"    
    wget_file = "data/historical_climate_wget_files.txt"
    
    # EXECUTION -----------------------------------------------------------------------------
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
    # Parameters set for Peninsula 
    # ========================================================================
    
    input_coord = "data/pre_processed_data/coordinates_peninsula_500_EPSG4326.txt"
    base_download_location = "data/pre_processed_data/Climate_Peninsula_500"
    
    wget_file = "data/historical_climate_wget_files.txt"
    
    # EXECUTION -----------------------------------------------------------------------------
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
    
   



