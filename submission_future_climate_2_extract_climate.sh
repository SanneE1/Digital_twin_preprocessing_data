#!/bin/bash
#SBATCH --job-name=extract_nc      # Job name
#SBATCH --nodes=1                   # Request one node
#SBATCH --ntasks=1                  # Run a single task
#SBATCH --mem=60G                   # Request 8 GB of memory
#SBATCH --output=job_reports/extract_output_%j.log        # Standard output and error log (%j expands to jobID)
#SBATCH --error=job_reports/extract_error_%j.log

# Run wget download line
Rscript R/extract_downloaded_data.R
