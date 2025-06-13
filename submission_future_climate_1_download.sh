#!/bin/bash
#SBATCH --job-name=download_nc      # Job name
#SBATCH --nodes=1                   # Request one node
#SBATCH --ntasks=1                  # Run a single task
#SBATCH --mem=16G                   # Request 8 GB of memory
#SBATCH --output=job_reports/down_output_%j.log        # Standard output and error log (%j expands to jobID)
#SBATCH --error=job_reports/down_error_%j.log

WGET_FILE=$1

# Run wget download line
wget --no-host-directories --force-directories --input-file=$WGET_FILE
