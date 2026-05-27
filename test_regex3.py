import re
ASSET_TYPES = ['jbib', 'teef', 'feet', 'lowr', 'accs', 'berd', 'hand', 'uppr', 'decl', 'task']

# Original failing one
regex_pattern1 = f"^(.*?)({'|'.join(ASSET_TYPES)})_(\\d+)(.*)$"
p1 = re.compile(regex_pattern1)

# New possible ones
regex_pattern2 = f"(.*?)({'|'.join(ASSET_TYPES)})_(\\d+)(.*)"
p2 = re.compile(regex_pattern2)

filename1 = "mp_f_freemode_01_mp_f_taticreations2^accs_001_u.ydd"
print("Testing p1")
print(p1.match(filename1))

print("Testing p2")
print(p2.search(filename1))
