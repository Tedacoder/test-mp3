import os
import re
import sys
import tkinter as tk
from tkinter import filedialog, messagebox
from tkinter.scrolledtext import ScrolledText

# Supported asset types based on the requirements
ASSET_TYPES = ['jbib', 'teef', 'feet', 'lowr', 'accs', 'berd', 'hand', 'uppr', 'decl', 'task']

# Compile a regular expression to match files
# Captures:
# 1. Any optional prefix before the asset type (e.g., "mp_f_freemode_01_mp_f_taticreations2^")
# 2. The asset type (e.g., jbib)
# 3. The original index/number (e.g., 000)
# 4. The rest of the filename (the suffix, e.g., _u.ydd)
regex_pattern = f"^(.*?)({'|'.join(ASSET_TYPES)})_(\\d+)(.*)$"
FILE_PATTERN = re.compile(regex_pattern)

def natural_sort_key(s):
    """
    Sort function to sort strings with numbers in human order (alphanumeric).
    E.g., Folder 1, Folder 2, Folder 10.
    """
    return [int(text) if text.isdigit() else text.lower()
            for text in re.split('([0-9]+)', s)]

class ClothingPackOrdererGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("GTA V Clothing Pack Orderer")
        self.root.geometry("600x500")

        self.root_dir = tk.StringVar(value="")
        self.dry_run = tk.BooleanVar(value=True)

        # Directory Selection Frame
        dir_frame = tk.Frame(root)
        dir_frame.pack(pady=10, padx=10, fill="x")

        tk.Label(dir_frame, text="Folder Path:").pack(side="left")
        tk.Entry(dir_frame, textvariable=self.root_dir, width=50).pack(side="left", padx=5)
        tk.Button(dir_frame, text="Browse...", command=self.browse_directory).pack(side="left")

        # Options Frame
        options_frame = tk.Frame(root)
        options_frame.pack(pady=5, padx=10, fill="x")

        tk.Checkbutton(options_frame, text="Dry Run (Preview only, no files changed)", variable=self.dry_run).pack(side="left")
        tk.Button(options_frame, text="Process Files", command=self.process_files, bg="green", fg="white").pack(side="right", padx=5)

        # Log Output Area
        log_frame = tk.Frame(root)
        log_frame.pack(pady=10, padx=10, fill="both", expand=True)
        tk.Label(log_frame, text="Log Output:").pack(anchor="w")

        self.log_area = ScrolledText(log_frame, state='disabled', wrap='word', height=15)
        self.log_area.pack(fill="both", expand=True)

    def browse_directory(self):
        folder_selected = filedialog.askdirectory()
        if folder_selected:
            self.root_dir.set(folder_selected)

    def log(self, message):
        self.log_area.config(state='normal')
        self.log_area.insert(tk.END, message + "\n")
        self.log_area.see(tk.END)
        self.log_area.config(state='disabled')
        self.root.update()

    def process_files(self):
        root_directory = self.root_dir.get()
        if not root_directory or not os.path.exists(root_directory):
            messagebox.showerror("Error", "Please select a valid directory.")
            return

        self.log_area.config(state='normal')
        self.log_area.delete('1.0', tk.END)
        self.log_area.config(state='disabled')

        self.log(f"Processing folders in: {os.path.abspath(root_directory)}")
        if self.dry_run.get():
            self.log("--- DRY RUN MODE ACTIVE: No files will be modified ---")

        all_entries = os.listdir(root_directory)
        subfolders = [d for d in all_entries if os.path.isdir(os.path.join(root_directory, d))]
        subfolders.sort(key=natural_sort_key)

        if not subfolders:
            self.log(f"No subfolders found in '{root_directory}'.")
            return

        global_counters = {asset: 0 for asset in ASSET_TYPES}

        for folder in subfolders:
            folder_path = os.path.join(root_directory, folder)
            self.log(f"\nProcessing Folder: {folder}")

            files_in_folder = [f for f in os.listdir(folder_path) if os.path.isfile(os.path.join(folder_path, f))]

            file_groups = {}
            for file in files_in_folder:
                match = FILE_PATTERN.match(file)
                if match:
                    prefix = match.group(1)
                    asset_type = match.group(2)
                    orig_index = match.group(3)

                    group_key = (asset_type, orig_index)
                    if group_key not in file_groups:
                        file_groups[group_key] = []
                    file_groups[group_key].append(file)

            if not file_groups:
                self.log("  No matching GTA V assets found in this folder.")
                continue

            sorted_group_keys = sorted(file_groups.keys(), key=lambda x: int(x[1]))
            temp_renames = []

            for group_key in sorted_group_keys:
                asset_type, orig_index = group_key
                files_in_group = file_groups[group_key]

                new_index = global_counters[asset_type]
                new_index_str = str(new_index).zfill(3)

                for file in files_in_group:
                    match = FILE_PATTERN.match(file)
                    prefix = match.group(1)
                    suffix = match.group(4)

                    final_name = f"{prefix}{asset_type}_{new_index_str}{suffix}"
                    temp_name = f"__TEMP_RENAME_{file}"

                    old_path = os.path.join(folder_path, file)
                    temp_path = os.path.join(folder_path, temp_name)

                    if self.dry_run.get():
                        self.log(f"  [Dry Run] {file} -> {final_name}")
                    else:
                        os.rename(old_path, temp_path)
                        temp_renames.append((temp_path, final_name, file))
                        self.log(f"  [Temp] {file} -> {temp_name}")

                global_counters[asset_type] += 1

            if not self.dry_run.get():
                for temp_path, final_name, orig_file in temp_renames:
                    final_path = os.path.join(os.path.dirname(temp_path), final_name)
                    os.rename(temp_path, final_path)
                    self.log(f"  [Final] {orig_file} -> {final_name}")

        self.log("\nProcessing complete.")
        messagebox.showinfo("Success", "Processing complete!")

if __name__ == "__main__":
    root = tk.Tk()
    app = ClothingPackOrdererGUI(root)
    root.mainloop()
