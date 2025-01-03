#!/bin/bash

# Array of file paths
FILES=(
  "modules/kuma/tokens/.control-plane-admin-user-token"
)

# Loop through each file path in the array
for FILE in "${FILES[@]}"; do
  # Check if the file already exists
  if [ ! -f "$FILE" ]; then
    # Create the directory if it doesn't exist
    mkdir -p "$(dirname "$FILE")"
    
    # Create the file and add content (if necessary)
    echo "token_content" > "$FILE"
    
    echo "File $FILE created successfully."
  else
    echo "File $FILE already exists."
  fi
done

echo "Project installed with success."