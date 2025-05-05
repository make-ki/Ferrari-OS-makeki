#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Directory setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$ROOT_DIR/configs"
PACKAGE_DIR="$CONFIG_DIR/packages"
WORK_DIR="$ROOT_DIR/work"
OUT_DIR="$ROOT_DIR/out"

# Create package directory if it doesn't exist
mkdir -p "$PACKAGE_DIR"

# Check for required package files
REQUIRED_FILES=("base.txt" "desktop.txt" "development.txt" "multimedia.txt")
MISSING_FILES=()

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$PACKAGE_DIR/$file" ]; then
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -ne 0 ]; then
    echo -e "${RED}Error: Missing required package files:${NC}"
    printf "${YELLOW}%s${NC}\n" "${MISSING_FILES[@]}"
    exit 1
fi

# Combine all package lists
echo -e "${BLUE}Gathering packages from:${NC}"
for file in "${REQUIRED_FILES[@]}"; do
    echo -e "${GREEN}- $file${NC}"
done

PACKAGES=""
for file in "${REQUIRED_FILES[@]}"; do
    # Extract packages, ignoring comments and empty lines
    FILE_PACKAGES=$(grep -v '^#' "$PACKAGE_DIR/$file" | grep -v '^$' | awk '{print $1}' | tr '\n' ' ')
    PACKAGES+="$FILE_PACKAGES "
done

# Clean previous build
if [ -d "$WORK_DIR" ]; then
    echo -e "${BLUE}Cleaning previous build...${NC}"
    rm -rf "$WORK_DIR"
fi

# Build ISO
echo -e "${GREEN}Building Ferrari OS ISO...${NC}"
echo -e "${BLUE}Total packages to be installed: $(echo $PACKAGES | wc -w)${NC}"

mkarchiso -v \
    -w "$WORK_DIR" \
    -o "$OUT_DIR" \
    -p "$PACKAGES" \
    "$CONFIG_DIR"

# Check if build was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Build completed successfully!${NC}"
    echo -e "ISO location: $OUT_DIR"
else
    echo -e "${RED}Build failed!${NC}"
    exit 1
fi