import sys
import os
import glob

def transform_asc_file(input_path, output_path):
    """
    Transform an ASC file by replacing the standard 6-line header with a simplified
    single-line 'ncols nrows' header.
    
    Args:
        input_path (str): Path to the input ASC file
        output_path (str): Path for the output file. If None, will create a file
                                    with '_transformed' suffix
    
    Returns:
        str: Path to the output file
    """
    
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

def process_folder(asc_folder, output_folder):
    """
    Process all .asc files in the specified folder and create corresponding .txt files
    with "Lynx_" prefix.
    
    Args:
        asc_folder (str): Path to the folder containing .asc files
        output_folder (str): Path to where the  .txt files need to be printed
    """
    # Make sure both folder path exists
    if not os.path.isdir(asc_folder):
        print(f"Error: Folder '{asc_folder}' does not exist")
        return
    
    if not os.path.exists(output_folder):
        os.makedirs(output_folder, exist_ok=True)
        
    # Get all .asc files in the folder
    asc_files = glob.glob(os.path.join(asc_folder, "*.asc"))
    
    if not asc_files:
        print(f"No .asc files found in '{asc_folder}'")
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
        output_file = os.path.join(output_folder, output_filename)
        
        # Transform the file
        transform_asc_file(asc_file, output_file)

