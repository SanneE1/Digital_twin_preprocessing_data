import sys
import os
import glob

def transform_asc_file(input_path, output_path=None):
    """
    Transform an ASC file by replacing the standard 6-line header with a simplified
    single-line 'ncols nrows' header.
    
    Args:
        input_path (str): Path to the input ASC file
        output_path (str, optional): Path for the output file. If None, will create a file
                                    with '_transformed' suffix
    
    Returns:
        str: Path to the output file
    """
    # Create output path if not provided
    if output_path is None:
        base, ext = os.path.splitext(input_path)
        output_path = f"{base}_transformed{ext}"
    
    ncols = None
    nrows = None
    
    try:
        with open(input_path, 'r') as infile, open(output_path, 'w') as outfile:
            # Read and parse the header
            for i in range(6):  # Standard ASC has 6 header lines
                line = infile.readline().strip()
                parts = line.split()
                
                if i == 0:  # ncols line
                    ncols = parts[1]
                elif i == 1:  # nrows line
                    nrows = parts[1]
            
            if ncols is None or nrows is None:
                raise ValueError("Could not find ncols or nrows in the ASC header")
            
            # Write the simplified header
            outfile.write(f"{ncols} {nrows}\n")
            
            # Copy the rest of the file (the raster data)
            for line in infile:
                outfile.write(line)
                
        print(f"Successfully transformed {input_path} to {output_path}")
        return output_path
        
    except Exception as e:
        print(f"Error transforming ASC file: {e}")
        if os.path.exists(output_path):
            try:
                os.remove(output_path)  # Clean up partial output file
            except:
                pass
        return None

def process_folder(folder_path):
    """
    Process all .asc files in the specified folder and create corresponding .txt files
    with "Lynx_" prefix.
    
    Args:
        folder_path (str): Path to the folder containing .asc files
    """
    # Make sure the folder path exists
    if not os.path.isdir(folder_path):
        print(f"Error: Folder '{folder_path}' does not exist")
        return
    
    # Get all .asc files in the folder
    asc_files = glob.glob(os.path.join(folder_path, "*.asc"))
    
    if not asc_files:
        print(f"No .asc files found in '{folder_path}'")
        return
    
    print(f"Found {len(asc_files)} .asc files to process")
    
    # Process each file
    for asc_file in asc_files:
        # Get directory path and filename
        dir_path = os.path.dirname(asc_file)
        filename = os.path.basename(asc_file)
        
        # Create output path with species prefix and .txt extension
        base_name, _ = os.path.splitext(filename)
        output_filename = f"{base_name}.txt"
        output_file = os.path.join("input_data", "maps", output_filename)
        
        # Transform the file
        transform_asc_file(asc_file, output_file)

if __name__ == "__main__":
    if len(sys.argv) > 1:
        # Use the folder path provided as a command-line argument
        folder_path = sys.argv[1]
    else:
        # Default folder path if none provided
        folder_path = "data/pre_processed_data"
    
    process_folder(folder_path)