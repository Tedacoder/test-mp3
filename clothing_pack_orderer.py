import os
import re
import sys

# Define the root directory to process.
# By default, it uses the current working directory, but you can change it to any absolute or relative path.
# Example: ROOT_DIR = "C:/Path/To/Your/Clothing/Pack"
ROOT_DIR = "."

# Allow passing the root directory as a command line argument
if len(sys.argv) > 1:
    ROOT_DIR = sys.argv[1]

# Supported asset types based on the requirements
ASSET_TYPES = ['jbib', 'teef', 'feet', 'lowr', 'accs', 'berd', 'hand', 'uppr', 'decl', 'task']

# Compile a regular expression to match files
# It captures:
# 1. The asset type (e.g., jbib)
# 2. The original index/number (e.g., 000)
# 3. The rest of the filename (the suffix, e.g., _u.ydd, _uni.ytd)
regex_pattern = f"^({'|'.join(ASSET_TYPES)})_(\\d+)(.*)$"
FILE_PATTERN = re.compile(regex_pattern)

def natural_sort_key(s):
    """
    Sort function to sort strings with numbers in human order (alphanumeric).
    E.g., Folder 1, Folder 2, Folder 10.
    """
    return [int(text) if text.isdigit() else text.lower()
            for text in re.split('([0-9]+)', s)]

def process_clothing_pack(root_directory):
    # Ensure the root directory exists
    if not os.path.exists(root_directory):
        print(f"Error: The directory '{root_directory}' does not exist.")
        return

    # List only directories inside the root directory
    all_entries = os.listdir(root_directory)
    subfolders = [d for d in all_entries if os.path.isdir(os.path.join(root_directory, d))]

    # Sort folders using natural sort (alphanumeric order)
    subfolders.sort(key=natural_sort_key)

    if not subfolders:
        print(f"No subfolders found in '{root_directory}'.")
        return

    # Maintain a global counter for each asset type across all folders.
    # Initializing at 0 to match 0-based index or as needed.
    global_counters = {asset: 0 for asset in ASSET_TYPES}

    print(f"Processing folders in: {os.path.abspath(root_directory)}")

    for folder in subfolders:
        folder_path = os.path.join(root_directory, folder)
        print(f"\nProcessing Folder: {folder}")

        # Get all files in the current subfolder
        files_in_folder = [f for f in os.listdir(folder_path) if os.path.isfile(os.path.join(folder_path, f))]

        # Group files by (asset_type, original_index) to ensure we rename models and textures to the same new index
        file_groups = {}
        for file in files_in_folder:
            match = FILE_PATTERN.match(file)
            if match:
                asset_type = match.group(1)
                orig_index = match.group(2)

                group_key = (asset_type, orig_index)
                if group_key not in file_groups:
                    file_groups[group_key] = []
                file_groups[group_key].append(file)

        if not file_groups:
            print("  No matching GTA V assets found in this folder.")
            continue

        # We process each group. To process them predictably, we sort the keys by original index.
        # This preserves the order *within* the folder.
        sorted_group_keys = sorted(file_groups.keys(), key=lambda x: int(x[1]))

        # We use a two-pass rename strategy (to __TEMP__, then to the final name)
        # to avoid collision in case the new name already exists in the folder.

        # Pass 1: Rename to temporary names and calculate final names
        temp_renames = [] # List of tuples: (temp_path, final_name)

        for group_key in sorted_group_keys:
            asset_type, orig_index = group_key
            files_in_group = file_groups[group_key]

            # The new index for this asset type is its current global counter
            new_index = global_counters[asset_type]
            new_index_str = str(new_index).zfill(3)

            for file in files_in_group:
                match = FILE_PATTERN.match(file)
                suffix = match.group(3)

                final_name = f"{asset_type}_{new_index_str}{suffix}"
                temp_name = f"__TEMP_RENAME_{file}"

                old_path = os.path.join(folder_path, file)
                temp_path = os.path.join(folder_path, temp_name)

                os.rename(old_path, temp_path)
                temp_renames.append((temp_path, final_name))
                print(f"  [Temp] {file} -> {temp_name}")

            # Increment the global counter for this asset type
            global_counters[asset_type] += 1

        # Pass 2: Rename from temp names to final names
        for temp_path, final_name in temp_renames:
            final_path = os.path.join(os.path.dirname(temp_path), final_name)
            os.rename(temp_path, final_path)
            # Find the original name from temp_name for better logging
            temp_name = os.path.basename(temp_path)
            orig_file = temp_name.replace("__TEMP_RENAME_", "")
            print(f"  [Final] {orig_file} -> {final_name}")

if __name__ == "__main__":
    process_clothing_pack(ROOT_DIR)
    print("\nProcessing complete.")
