# Digital_twin_preprocessing_data

Repository with scripts to process data needed to run the Lynx-Rabbit IBMs

## Currently 3 "workflows"

**pre_processing_input_files.py**: wrapper for the scripts to format the input habitat maps and download/format historical climate.  
**submission_future_climate_\* files**: ordered submission files to download and format future climate from CHELSA, using the wget files in the data folder.  
**Create_input_parameter_files.py**: A very simple script, that currently write the two text files needed as input for the model. With development of the digital twin, this can be updated to include parameters estimated from model callibration and user input.
Also creates files with Lynx starting population and re-introduced individuals *Currently dummy values to be able to run the models*

## Data needed not currently in the wrapper/processes
CORINE Land Cover:  
the wrappers expect the following file: data/original_data/U2018_CLC2018_V2020_20u1.tif  
[doi: 10.2909/960998c1-1870-4e82-8051-6485205ebbac](https://doi.org/10.2909/960998c1-1870-4e82-8051-6485205ebbac)  

IUCN Spatial Data - polygons:  
The lynx wrapper expects polygon files downloaded from [this page, in the section of the Mammals - Terrestrial Mammals](https://www.iucnredlist.org/resources/spatial-data-download) (Last accessed 2024-12-10 at 13:47:35)  
The files then need to be stored in: data/original_data/IUCN/  


