#!/bin/bash

# Name of this script
script_name=$(basename "$0")
tmp_suffix=".tmp_rename"

# Cleanup any leftover temp files from a previously interrupted run
rm -f *"$tmp_suffix" 2>/dev/null

# Step 1: Find the end of the continuous valid sequence (001.jpg, 002.jpg...)
max_valid=0
while true; do
  next_name=$(printf "%03d.jpg" $((max_valid + 1)))
  if [ -e "$next_name" ]; then
    ((max_valid++))
  else
    break
  fi
done

echo "Continuous sequence currently ends at: $(printf "%03d.jpg" "$max_valid")"

# Step 2: Identify files that need fixing and queue them up safely
temp_files=()
temp_counter=1

for file in *; do
  # Skip directories, the script itself, and non-existent files
  [ -d "$file" ] && continue
  [ "$file" = "$script_name" ] && continue
  [ ! -e "$file" ] && continue

  ext="${file##*.}"
  ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
  base="${file%.*}"

  # Check if the file is already perfectly formatted and in-sequence
  is_valid=false
  if [[ "$ext_lower" == "jpg" ]] && [[ "$base" =~ ^([0-9]+)$ ]]; then
    # Strip leading zeros for bash arithmetic
    num=$((10#${BASH_REMATCH[1]}))
    if ((num > 0 && num <= max_valid)); then
      # Ensure it has exact zero-padding (e.g., forces "1.jpg" to be fixed to "001.jpg")
      expected_name=$(printf "%03d.jpg" "$num")
      if [[ "$file" == "$expected_name" ]]; then
        is_valid=true
      fi
    fi
  fi

  # If it is part of the clean 001...N block, leave it completely alone
  if [ "$is_valid" = true ]; then
    continue
  fi

  # File needs fixing (out of bounds, gap, wrong extension, wrong padding)
  # Move it to a safe temp name so we guarantee no accidental overwrites
  temp_name="queue_${temp_counter}${tmp_suffix}"
  ((temp_counter++))

  if [[ "$ext_lower" != "jpg" ]]; then
    magick "$file" "$temp_name" && rm "$file"
    echo "Converted and queued: $file"
  else
    mv "$file" "$temp_name"
    echo "Queued for rename: $file"
  fi

  # Store the temp name in an array for Step 3
  temp_files+=("$temp_name")
done

# Step 3: Assign the next available continuous numbers to the queued files
for tmp_file in "${temp_files[@]}"; do
  ((max_valid++))
  final_name=$(printf "%03d.jpg" "$max_valid")
  mv "$tmp_file" "$final_name"
  echo "Finalized: -> $final_name"
done

echo "✅ Done: All gaps closed and stray wallpapers snapped to the sequence."
