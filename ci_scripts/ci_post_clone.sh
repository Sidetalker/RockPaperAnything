#!/bin/sh

# Define the source and destination file paths
source_file="ci_env"
destination_file="../.env"

# Check if the source file exists
if [[ -f "$source_file" ]]; then
    # Copy the source file to the destination
    cp "$source_file" "$destination_file"
    echo "File copied successfully to $destination_file"
else
    echo "Source file $source_file does not exist."
fi
