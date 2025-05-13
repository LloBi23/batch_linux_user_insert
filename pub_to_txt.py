#!/usr/bin/env python3
import os

# Determine the folder where this script lives
script_dir = os.path.dirname(os.path.abspath(__file__))

for fname in os.listdir(script_dir):
    if fname.endswith('.pub'):
        base = os.path.splitext(fname)[0]
        src = os.path.join(script_dir, fname)
        dst = os.path.join(script_dir, base + '.txt')

        with open(src, 'r') as f_in, open(dst, 'w') as f_out:
            f_out.write(f_in.read())

        print(f"{fname} → {base}.txt")

print("Done.")
