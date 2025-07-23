#!/bin/bash
#SBATCH --job-name=extract_nc      # Job name
#SBATCH --nodes=1                   # Request one node
#SBATCH --ntasks=1                  # Run a single task
#SBATCH --mem=60G                   # Request 8 GB of memory
#SBATCH --output=job_reports/extract_output_%j.log        # Standard output and error log (%j expands to jobID)
#SBATCH --error=job_reports/extract_error_%j.log

COOR_FILE=$1   # Coordinates in EPSG4326
SPAT_SCALE=$2  # Either peninsula or donana - used for naming the folder to keep them seperate

# Run wget download line
Rscript R/extract_downloaded_data.R $COOR_FILE $SPAT_SCALE
