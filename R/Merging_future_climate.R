library(data.table)  

args = commandArgs(trailingOnly = T)

download_location <- sub("/$", "", args[1]) 
year_min <- as.integer(args[2])
year_max <- as.integer(args[3])


# Function to merge chunk files into a single output file using data.table
merge_chunk_files <- function(base_filename, output_filename) {
  # Get start time
  start_time <- Sys.time()
  
  # List all chunk files
  base_dir <- dirname(base_filename)
  base_name <- basename(base_filename)
  pattern <- paste0("^", base_name, "_chunk_.*\\.txt$")
  chunk_files <- list.files(path = base_dir, pattern = pattern, full.names = TRUE)
  
  cat("Found", length(chunk_files), "chunk files to merge for", base_filename, "\n")
  
  if (length(chunk_files) == 0) {
    stop("No chunk files found for ", base_filename)
  }
  
  # Sort files for consistent ordering
  chunk_files <- sort(chunk_files)
  
  # Process headers (we need to write them only once)
  header <- fread(chunk_files[1], nrows = 1)
  
  # Write the header to the output file
  fwrite(header, output_filename, col.names = TRUE, row.names = FALSE, quote = FALSE, sep = " ")
  
  # Counter for total rows
  total_rows <- 0
  
  # Process each chunk file
  for (i in seq_along(chunk_files)) {
    if (i %% 50 == 0) {
      cat("Processing file", i, "/", length(chunk_files), ":", chunk_files[i], "\n")
    }
    
    # Use data.table's fread for faster reading
    chunk_dt <- tryCatch({
      # Skip headers since we've already written them
      fread(chunk_files[i], skip = 1)
    }, error = function(e) {
      cat("Error reading", chunk_files[i], ":", conditionMessage(e), "\n")
      NULL
    })
    
    if (!is.null(chunk_dt) && nrow(chunk_dt) > 0) {
      # Write the data to the output file, appending to existing content
      fwrite(chunk_dt, output_filename, col.names = FALSE, row.names = FALSE, 
             quote = FALSE, sep = " ", append = TRUE)
      
      total_rows <- total_rows + nrow(chunk_dt)
      
      # Important: Remove the chunk_dt to free memory immediately
      rm(chunk_dt)
      gc()
    }
  }
  
  # Calculate elapsed time
  end_time <- Sys.time()
  elapsed <- difftime(end_time, start_time, units = "secs")
  
  cat("Total rows merged:", total_rows, "\n")
  cat("Merge completed in", round(as.numeric(elapsed), 2), "seconds\n")
  
  # Optionally, clean up chunk files
  # file.remove(chunk_files)
  # cat("Removed", length(chunk_files), "chunk files\n")
}

cat("Starting merge operation...\n")

# Merge breeding months files
cat("\n=== Processing breeding months files ===\n")
merge_chunk_files(
  base_filename = file.path(download_location, paste("breeding_months", download_location, year_min, year_max, sep = "_")),
  output_filename = file.path("final_files", paste0(paste("breeding_months", download_location, year_min, year_max, sep = "_"), '.txt'))
)

# Merge consecutive dry months files
cat("\n=== Processing consecutive dry months files ===\n")
merge_chunk_files(
  base_filename = file.path(download_location, paste("consecutive_dry_months", download_location, year_min, year_max, sep = "_")),
  output_filename = file.path("final_files", paste0(paste("consecutive_dry_months", download_location, year_min, year_max, sep = "_"), '.txt'))
)

cat("All merges completed successfully!\n")
