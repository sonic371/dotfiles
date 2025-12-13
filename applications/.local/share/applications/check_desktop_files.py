#!/usr/bin/env python3
import os
import re
import subprocess
import sys

def check_desktop_files():
    desktop_dir = "."
    broken_files = []
    valid_files = []

    for filename in os.listdir(desktop_dir):
        if not filename.endswith(".desktop"):
            continue

        filepath = os.path.join(desktop_dir, filename)
        exec_path = None

        try:
            with open(filepath, 'r') as f:
                content = f.read()

            # Find Exec line
            exec_match = re.search(r'^Exec=(.+)$', content, re.MULTILINE)
            if not exec_match:
                print(f"{filename}: No Exec line found")
                continue

            exec_line = exec_match.group(1)

            # Clean up the exec path (remove parameters and quotes)
            # Remove parameters like %U, %f, %F, %u
            exec_clean = re.sub(r' %[UufF].*$', '', exec_line)
            # Remove surrounding quotes if present
            if exec_clean.startswith('"') and exec_clean.endswith('"'):
                exec_clean = exec_clean[1:-1]
            elif exec_clean.startswith("'") and exec_clean.endswith("'"):
                exec_clean = exec_clean[1:-1]

            exec_path = exec_clean

            # Check if file exists
            if os.path.isfile(exec_path):
                print(f"{filename}: ✓ Executable exists: {exec_path}")
                valid_files.append(filename)
            elif os.path.isabs(exec_path):
                # Absolute path that doesn't exist
                print(f"{filename}: ✗ Broken - file not found: {exec_path}")
                broken_files.append((filename, exec_path))
            else:
                # Check if it's in PATH
                try:
                    subprocess.run(["which", exec_path], check=True, capture_output=True)
                    print(f"{filename}: ✓ Command in PATH: {exec_path}")
                    valid_files.append(filename)
                except subprocess.CalledProcessError:
                    print(f"{filename}: ✗ Broken - command not in PATH: {exec_path}")
                    broken_files.append((filename, exec_path))

        except Exception as e:
            print(f"{filename}: Error reading file: {e}")

    print("\n" + "="*60)
    print(f"Summary: {len(valid_files)} valid, {len(broken_files)} broken")

    if broken_files:
        print("\nBroken desktop entries (consider removing):")
        for filename, exec_path in broken_files:
            print(f"  {filename}: {exec_path}")

    return broken_files

if __name__ == "__main__":
    check_desktop_files()