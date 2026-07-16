#!/bin/bash

script_name=$(basename "$0")
tmp_suffix=".tmp_rename"

shopt -s nullglob

leftover=(*"$tmp_suffix")
if [ "${#leftover[@]}" -gt 0 ]; then
  echo "Error: leftover temp files from a previous interrupted run were found:" >&2
  printf '  %s\n' "${leftover[@]}" >&2
  echo "Resolve them manually before running this script again." >&2
  exit 1
fi

max_valid=0
while true; do
  next_name=$(printf "%03d.jpg" $((max_valid + 1)))
  if [ -e "$next_name" ]; then
    max_valid=$((max_valid + 1))
  else
    break
  fi
done
echo "Continuous sequence currently ends at: $(printf "%03d.jpg" "$max_valid")"

temp_files=()
temp_counter=1
for file in *; do
  [ -d "$file" ] && continue
  [ "$file" = "$script_name" ] && continue
  [ ! -e "$file" ] && continue

  if [[ "$file" == *.* ]]; then
    ext="${file##*.}"
    base="${file%.*}"
  else
    ext=""
    base="$file"
  fi
  ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

  is_valid=false
  if [[ "$ext_lower" == "jpg" ]] && [[ "$base" =~ ^([0-9]+)$ ]]; then
    num=$((10#${BASH_REMATCH[1]}))
    if ((num > 0 && num <= max_valid)); then
      expected_name=$(printf "%03d.jpg" "$num")
      if [[ "$file" == "$expected_name" ]]; then
        is_valid=true
      fi
    fi
  fi

  if [ "$is_valid" = true ]; then
    continue
  fi

  temp_name="queue_${temp_counter}${tmp_suffix}"

  if [[ "$ext_lower" != "jpg" ]]; then
    if ! command -v magick >/dev/null 2>&1; then
      echo "Error: 'magick' command not found; cannot convert $file" >&2
      continue
    fi
    if magick "$file" "jpg:$temp_name" && rm "$file"; then
      echo "Converted and queued: $file"
      temp_counter=$((temp_counter + 1))
      temp_files+=("$temp_name")
    else
      echo "Warning: failed to convert $file; left untouched" >&2
    fi
  else
    if mv "$file" "$temp_name"; then
      echo "Queued for rename: $file"
      temp_counter=$((temp_counter + 1))
      temp_files+=("$temp_name")
    else
      echo "Warning: failed to move $file; left untouched" >&2
    fi
  fi
done

for tmp_file in "${temp_files[@]}"; do
  max_valid=$((max_valid + 1))
  final_name=$(printf "%03d.jpg" "$max_valid")
  mv "$tmp_file" "$final_name"
  echo "Finalized: $tmp_file -> $final_name"
done

echo "Done: all gaps closed and stray files renamed into the sequence."
