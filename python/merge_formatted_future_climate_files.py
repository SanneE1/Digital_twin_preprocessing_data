import os
import pandas as pd
import glob
import time
import sys

def merge_chunk_files(base_filename, output_filename):
    """
    Merge all chunk files with the given base filename into a single output file.
    
    Args:
        base_filename: Base filename pattern to match chunk files
        output_filename: Output file to write merged data
    """
    start_time = time.time()
    
    # Find all chunk files
    base_dir = os.path.dirname(base_filename)
    base_name = os.path.basename(base_filename)
    pattern = f"{base_dir}/{base_name}_chunk_*.txt"
    chunk_files = glob.glob(pattern)
    
    print(f"Found {len(chunk_files)} chunk files to merge for {base_filename}")
    
    if len(chunk_files) == 0:
        print(f"Error: No chunk files found for {base_filename}")
        return
    
    # Sort files to ensure consistent ordering
    chunk_files.sort()
    
    # Use a list to collect all dataframes
    dfs = []
    
    # Process each chunk file
    for i, file in enumerate(chunk_files):
        if i % 100 == 0:  # Print progress every 100 files
            print(f"Reading file {i+1}/{len(chunk_files)}: {file}")
        
        try:
            # Read the chunk file
            df = pd.read_csv(file, sep='\s+')
            dfs.append(df)
        except Exception as e:
            print(f"Error reading {file}: {e}")
    
    print(f"Concatenating {len(dfs)} dataframes...")
    # Concatenate all dataframes at once (more efficient than incremental merging)
    merged_df = pd.concat(dfs, ignore_index=True)
    
    print(f"Total rows in merged file: {len(merged_df)}")
    
    # Write the merged results to the output file
    print(f"Writing merged file to {output_filename}...")
    merged_df.to_csv(output_filename, sep=' ', index=False)
    
    elapsed_time = time.time() - start_time
    print(f"Merge completed in {elapsed_time:.2f} seconds")
    
    # Optionally, clean up chunk files
    # print("Removing chunk files...")
    # for file in chunk_files:
    #     os.remove(file)
    # print(f"Removed {len(chunk_files)} chunk files")

if __name__ == "__main__":
    print("Starting merge operation...")
    
    # Merge breeding months files
    print("\n=== Processing breeding months files ===")
    merge_chunk_files(
        base_filename="data_formatting/breeding_months_500_peninsula_2006-2029",
        output_filename="data_formatting/breeding_months_500_peninsula_2006-2029.txt"
    )
    
    # Merge consecutive dry months files
    print("\n=== Processing consecutive dry months files ===")
    merge_chunk_files(
        base_filename="data_formatting/consecutive_dry_months_500_peninsula_2006-2029",
        output_filename="data_formatting/consecutive_dry_months_500_peninsula_2006-2029.txt"
    )
    
    print("All merges completed successfully!")
