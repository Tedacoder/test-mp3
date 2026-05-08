with open('clothing_pack_orderer.py', 'r') as f:
    content = f.read()

old = """                for file in files_in_group:
                    match = FILE_PATTERN.match(file)
                    prefix = match.group(1)
                    suffix = match.group(4)

                    final_name = f"{prefix}{asset_type}_{new_index_str}{suffix}"
                    temp_name = f"__TEMP_RENAME_{file}" """

new = """                for file, orig_asset_case in files_in_group:
                    match = FILE_PATTERN.match(file)
                    prefix = match.group(1)
                    suffix = match.group(4)

                    final_name = f"{prefix}{orig_asset_case}_{new_index_str}{suffix}"
                    temp_name = f"__TEMP_RENAME_{file}" """

content = content.replace(old, new)

with open('clothing_pack_orderer.py', 'w') as f:
    f.write(content)
