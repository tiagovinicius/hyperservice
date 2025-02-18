# Read current version from version.txt
VERSION=$(cat version.txt)

# Extract the base name (app name) and the current version
BASE_NAME=$(echo "$VERSION" | cut -d'-' -f1)
CURRENT_VERSION=$(echo "$VERSION" | cut -d'-' -f2-)

# Increment PATCH version (you can modify this for MINOR or MAJOR as needed)
NEW_VERSION=$(echo "$CURRENT_VERSION" | awk -F. -v OFS=. '{$NF++;print}')

# Combine the base name with the new version
NEW_FULL_VERSION="$BASE_NAME-$NEW_VERSION"

# Update version.txt with the new version
echo "$NEW_FULL_VERSION" > version.txt

# Commit version.txt update
git add version.txt
git commit -m "Bump version to $NEW_FULL_VERSION"

# Push the commit and the version tag
git push
git tag "$BASE_NAME-$NEW_VERSION"
git push origin "$BASE_NAME-$NEW_VERSION"

# Rename the binary to include the version
mv ./bin/main "./bin/$BASE_NAME-$NEW_VERSION"