#!/bin/bash

cd "$(dirname "$0")"

SOURCE_DIRS=("./bin" "./mc/bin" "./web/bin") # Array for source directories
DEST_DIR="/usr/local/bin"
EXCLUDE_EXTENSIONS=".ps1" # Default exclude extensions

# Function to display options with numbers
display_options() {
  local -n arr="$1" # Declare a local name reference to the first argument (the array)
  for i in "${!arr[@]}"; do
    echo "[$((i + 1))] ${arr[$i]}"
  done
}

# Ask the user to select source directories
echo "Select the directories to make global (enter numbers separated by spaces):"
display_options SOURCE_DIRS
read -ra selected_indices

selected_source_dirs=()
for index in "${selected_indices[@]}"; do
  if [[ "$index" -ge 1 && "$index" -le "${#SOURCE_DIRS[@]}" ]]; then
    selected_source_dirs+=("${SOURCE_DIRS[$((index - 1))]}")
  else
    echo "Invalid selection: $index. Skipping."
  fi
done

if [[ -z "${selected_source_dirs[@]}" ]]; then
  echo "No directories selected. Exiting."
  exit 1
fi

# Ask if .sh should be included
read -p "Include files ending with '.sh'? (y/n, default: y): " include_sh_response
include_sh=true
if [[ -n "$include_sh_response" && "$include_sh_response" != "y" ]]; then
  include_sh=false
fi

# Ask for exclude extensions
read -p "Enter extensions to exclude (comma-separated, default: $EXCLUDE_EXTENSIONS): " exclude_extensions_input
if [[ -n "$exclude_extensions_input" ]]; then
  EXCLUDE_EXTENSIONS="$exclude_extensions_input"
fi
IFS=',' read -ra exclude_extensions_array <<<"$EXCLUDE_EXTENSIONS"

echo "Processing the following directories:"
for dir in "${selected_source_dirs[@]}"; do
  echo "- $dir"
done

if "$include_sh"; then
  echo "Including .sh files."
else
  echo "Excluding .sh files."
fi

echo "Excluding files with extensions: ${exclude_extensions_array[*]}"

for source_dir in "${selected_source_dirs[@]}"; do
  find "$source_dir" -maxdepth 1 -type f -print0 | while IFS= read -r -d $'\0' file; do
    filename=$(basename "$file")
    extension="${filename##*.}"

    skip_file=false
    for exclude_ext in "${exclude_extensions_array[@]}"; do
      if [[ "$extension" == "${exclude_ext#*.}" ]]; then
        skip_file=true
        break
      fi
    done

    if "$skip_file"; then
      echo "Skipping file with excluded extension: $file"
      continue
    fi

    if "$include_sh" || [[ "$filename" != *.sh ]]; then
      dest_file="$DEST_DIR/${filename%.*}" # Remove any extension

      if [ -f "$file" ]; then
        sudo cp "$file" "$dest_file"
        sudo chmod +x "$dest_file"
        echo "Successfully copied: $file -> $dest_file"
      else
        echo "File not found: $file"
      fi
    fi
  done
done

echo "Processing complete."
