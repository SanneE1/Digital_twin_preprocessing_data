#!/bin/bash
#SBATCH --job-name=download_nc      # Job name
#SBATCH --nodes=1                   # Request one node
#SBATCH --ntasks=1                  # Run a single task
#SBATCH --mem=30G                   # Request 8 GB of memory
#SBATCH --output=job_reports/merge_output_%j.log        # Standard output and error log (%j expands to jobID)
#SBATCH --error=job_reports/merge_error_%j.log

DOWN_DIR=$1
YEAR_MIN=$2
YEAR_MAX=$3

# Run wget download line
Rscript R/Merging_future_climate.R $DOWN_DIR $YEAR_MIN $YEAR_MAX
