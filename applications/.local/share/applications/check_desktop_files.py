#!/usr/bin/env python3
import os
import re
import subprocess
import sys
import shlex

def get_executable_from_exec_line(exec_line):
    """
    Extract the actual executable path/name from an Exec line.
    Handles common patterns like:
    - Simple commands: "firefox"
    - With arguments: "firefox %U"
    - With env: "env VAR=value command"
    - With bash -c: "bash -c 'command'"
    - With flatpak: "flatpak run app"
    - With wine: "env WINEPREFIX=... wine start ..."
    """
    # Remove trailing comments and % parameters
    exec_line = re.sub(r' %[UufFdDnNickvm]', '', exec_line)
    exec_line = re.sub(r' #.*$', '', exec_line)
    
    # Try to parse with shlex to handle quotes properly
    try:
        parts = shlex.split(exec_line)
    except ValueError:
        # If shlex fails, fall back to simple split
        parts = exec_line.split()
    
    if not parts:
        return None
    
    # Handle common prefixes
    if parts[0] == 'env':
        # Skip environment variables (VAR=value) until we find a command
        for i, part in enumerate(parts[1:], 1):
            if '=' not in part:
                return parts[i]
        return None
    elif parts[0] == 'bash' or parts[0] == 'sh':
        # For bash -c "command", extract the command
        if len(parts) >= 3 and parts[1] == '-c':
            # The command might be in quotes, try to extract it
            cmd_part = ' '.join(parts[2:])
            # Remove surrounding quotes
            cmd_part = re.sub(r'^["\']|["\']$', '', cmd_part)
            # Get the first word of the command
            cmd_parts = shlex.split(cmd_part) if cmd_part else []
            return cmd_parts[0] if cmd_parts else parts[0]
        return parts[0]
    elif parts[0] == 'flatpak':
        # flatpak run APP_NAME
        if len(parts) >= 3 and parts[1] == 'run':
            return parts[2] if len(parts) > 2 else None
        return None
    elif parts[0] == 'wine':
        # wine start /ProgIDOpen "file"
        return 'wine'
    else:
        # Simple command or path
        return parts[0]

def check_desktop_files():
    desktop_dir = "."
    broken_files = []
    valid_files = []
    warning_files = []

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
            executable = get_executable_from_exec_line(exec_line)
            
            if not executable:
                print(f"{filename}: Could not parse Exec line: {exec_line}")
                warning_files.append((filename, "Could not parse Exec line"))
                continue

            # Check if executable exists
            if os.path.isabs(executable):
                # Absolute path
                if os.path.isfile(executable) and os.access(executable, os.X_OK):
                    print(f"{filename}: ✓ Executable exists: {executable}")
                    valid_files.append(filename)
                else:
                    print(f"{filename}: ✗ Broken - file not found/not executable: {executable}")
                    broken_files.append((filename, executable, exec_line))
            else:
                # Check if command exists in PATH
                try:
                    result = subprocess.run(["which", executable], 
                                          capture_output=True, text=True)
                    if result.returncode == 0:
                        print(f"{filename}: ✓ Command in PATH: {executable} -> {result.stdout.strip()}")
                        valid_files.append(filename)
                    else:
                        # Try using type as fallback
                        try:
                            subprocess.run(["type", executable], 
                                         capture_output=True, check=True)
                            print(f"{filename}: ✓ Command available: {executable}")
                            valid_files.append(filename)
                        except subprocess.CalledProcessError:
                            print(f"{filename}: ✗ Broken - command not in PATH: {executable}")
                            broken_files.append((filename, executable, exec_line))
                except FileNotFoundError:
                    # which command not available, try type
                    try:
                        subprocess.run(["type", executable], 
                                     capture_output=True, check=True)
                        print(f"{filename}: ✓ Command available: {executable}")
                        valid_files.append(filename)
                    except (subprocess.CalledProcessError, FileNotFoundError):
                        print(f"{filename}: ✗ Broken - command not in PATH: {executable}")
                        broken_files.append((filename, executable, exec_line))

        except Exception as e:
            print(f"{filename}: Error reading file: {e}")
            warning_files.append((filename, f"Error: {e}"))

    print("\n" + "="*60)
    print(f"Summary: {len(valid_files)} valid, {len(broken_files)} broken, {len(warning_files)} warnings")

    if broken_files:
        print("\nBroken desktop entries (consider removing/fixing):")
        for filename, executable, exec_line in broken_files:
            print(f"  {filename}: {executable}")
            print(f"    Exec: {exec_line[:80]}{'...' if len(exec_line) > 80 else ''}")

    if warning_files:
        print("\nWarnings (entries that need manual review):")
        for filename, warning in warning_files:
            print(f"  {filename}: {warning}")

    return broken_files

if __name__ == "__main__":
    check_desktop_files()
