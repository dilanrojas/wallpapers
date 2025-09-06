#!/bin/bash

# Name of this script
script_name=$(basename "$0")

# Temp suffix to avoid name collisions
tmp_suffix=".tmp_rename"

# Step 1: Convert all non-JPG files to JPG (and remove originals)
for file in *; do
    # Skip directories and this script
    [ -d "$file" ] && continue
    [ "$file" = "$script_name" ] && continue

    # Get lowercase extension
    ext="${file##*.}"
    ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

    if [[ "$ext_lower" != "jpg" ]]; then
        base="${file%.*}"
        new_file="${base}.jpg"

        # Convert to JPG and delete original
        magick "$file" "$new_file" && rm "$file"
        echo "Converted: $file -> $new_file"
    fi
done

# Step 2: Rename all JPGs to temporary numbered names to avoid conflicts
counter=1
for file in *.jpg; do
    [ "$file" = "$script_name" ] && continue
    tmp_name=$(printf "%03d%s" "$counter" "$tmp_suffix")
    mv "$file" "$tmp_name"
    ((counter++))
done

# Step 3: Rename temporary files to final names (001.jpg, 002.jpg, etc.)
counter=1
for file in *"$tmp_suffix"; do
    final_name=$(printf "%03d.jpg" "$counter")
    mv "$file" "$final_name"
    ((counter++))
done

echo "✅ Done: All wallpapers converted and renamed in-place."
