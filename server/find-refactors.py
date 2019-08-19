#!/usr/bin/env python

import sys
import os
import os.path
import re

# Make sure we pass the file name
if len(sys.argv) < 2:
    print("Usage: python3 find-refactors.py <filename>")
    exit(1)

# Get the file, failing if it does not exist
fpath = sys.argv[1]
if not os.path.exists(fpath):
    print("Error: " + fpath + " does not exist")
    exit(1)

# Group by cancellations
group_ends = []
group_starts = []
group_lines = []
with open(fpath, 'r') as f:
    groups = re.split("\(\*CANCEL.*\*\)\s+", f.read())
    for group in groups:
        _, *lines = re.split("\s*\(\*", group)
        for line_num, line in enumerate(lines, start = 0):
            line = "(*" + line.strip()
            state_num = int(re.search("\(\*(\d+):\*\)", line).group(1))
            if line_num == 0:
                group_starts.append(state_num)
            if line_num == len(lines) - 1:
                group_ends.append(state_num)
            line = re.sub("\(\*(\d+):\*\)\s+", "", line)
            lines[line_num] = line
        if (len(lines) > 0):
            group_lines.append(lines)

# Now go through the cancellation and, for proof of concept, show first changed pair
for i in range(len(group_ends) - 1):
    j = i + 1
    k = i
    while (group_starts[j] < group_starts[k]):
        k = k - 1
    old_line_num = 0
    if group_starts[j] != group_starts[k]:
        if k == 0:
            old_line_num = group_starts[j] - group_starts[k]
        else:
            real_start = group_ends[k] - len(group_lines[k]) + 1
            old_line_num = group_starts[j] - real_start
    print("old: " + group_lines[k][old_line_num])
    print("new: " + group_lines[j][0])
    print("\n")
        

# Not done yet: compare each pair, group if similar enough, otherwise call "different"
