#!/bin/bash
#SBATCH --job-name=format_nc        # Job name
#SBATCH --nodes=1                   # Request one node
#SBATCH --ntasks=1                  # Run a single task
#SBATCH --array=1-1000
#SBATCH --mem=3G                   # Request 8 GB of memory
#SBATCH --output=job_reports/format_output_%j.log        # Standard output and error log (%j expands to jobID)
#SBATCH --error=job_reports/format_error_%j.log

DOWN_DIR=$1
YEAR_MIN=$2
YEAR_MAX=$3
SPAT_OPTION=$4

# Run wget download line
Rscript R/Formatting_climate_data.R $SLURM_ARRAY_TASK_ID 1000 $DOWN_DIR $YEAR_MIN $YEAR_MAX $SPAT_OPTION
