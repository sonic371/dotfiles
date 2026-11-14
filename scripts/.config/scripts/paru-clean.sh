#!/bin/bash
# Clean all paru cache directories, keeping only latest versions

for pkg_dir in ~/.cache/paru/clone/*; do
    if [ -d "$pkg_dir" ]; then
        echo "Cleaning: $(basename "$pkg_dir")"
        cd "$pkg_dir" || continue
        
        # Function to clean file types
        clean_files() {
            local pattern=$1
            # Use while-read to handle spaces in filenames
            ls -t $pattern 2>/dev/null | tail -n +2 | while IFS= read -r file; do
                [[ -n "$file" ]] && rm -f "$file"
            done
        }
        
        # Clean source archives
        clean_files "*.tar.gz"
        clean_files "*.tar.xz" 
        clean_files "*.tar.bz2"
        clean_files "*.zip"
        
        # Clean package files
        clean_files "*.pkg.tar.zst"
        clean_files "*.pkg.tar.xz"
        
        # Clean .deb files
        clean_files "*.deb"
        
        # Remove partial downloads
        rm -f *.part 2>/dev/null
    fi
done

echo "Cleanup complete!"
