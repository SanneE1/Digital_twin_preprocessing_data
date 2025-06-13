import os
import subprocess

os.environ["R_HOME"] =  "C:/Users/Z1512834Z/AppData/Local/Programs/R/R-4.4.0"  

import rpy2.robjects as robjects

# Reclassify CORINE map for lynx
robjects.r.source('R/Reclassify_Lynx_spatial_map.R')

# Change maps to input format needed for model
subprocess.run(["python", "python/transform_asc_to_input_txt_map.py"],
               capture_output=True)
