#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Building NeoAI Chat Desktop Application${NC}"

# Check if we're in the right directory
if [ ! -f "Cargo.toml" ]; then
    echo -e "${RED}Error: Cargo.toml not found. Please run this script from the project root.${NC}"
    exit 1
fi

# Create necessary directories
mkdir -p assets/src
mkdir -p assets/dist

# Check if icon exists, create fallback if not
if [ ! -f "icon.png" ]; then
    echo -e "${YELLOW}Warning: icon.png not found. Creating a simple fallback icon...${NC}"
    
    # Try to convert SVG to PNG if possible
    if command -v rsvg-convert &> /dev/null && [ -f "icon.svg" ]; then
        rsvg-convert icon.svg -o icon.png
        echo -e "${GREEN}✓ Converted icon.svg to icon.png${NC}"
    elif command -v convert &> /dev/null && [ -f "icon.svg" ]; then
        convert icon.svg icon.png
        echo -e "${GREEN}✓ Converted icon.svg to icon.png${NC}"
    else
        echo -e "${YELLOW}Note: Install ImageMagick or librsvg to convert icon.svg to icon.png${NC}"
        echo -e "${YELLOW}      The application will use a generated fallback icon.${NC}"
    fi
fi

# Check if index.html exists in assets/dist or create from current
if [ ! -f "index.html" ] && [ -f "assets/dist/index.html" ]; then
    cp assets/dist/index.html .
    echo -e "${GREEN}✓ Copied built index.html from assets/dist${NC}"
elif [ ! -f "index.html" ]; then
    echo -e "${RED}Error: index.html not found. Please build your web assets first.${NC}"
    echo -e "${YELLOW}Expected location: assets/dist/index.html${NC}"
    exit 1
fi

# Validate required files
echo -e "${GREEN}Validating project structure...${NC}"

required_files=("Cargo.toml" "src/main.rs" "src/icon.rs" "build.rs")
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "  ✓ $file"
    else
        echo -e "  ${RED}✗ $file (missing)${NC}"
        exit 1
    fi
done

# Build the Rust application
echo -e "${GREEN}Building Rust application...${NC}"

if command -v cargo &> /dev/null; then
    # Check if we're in release mode
    if [ "$1" = "--release" ]; then
        echo -e "${YELLOW}Building in release mode...${NC}"
        cargo build --release
        echo -e "${GREEN}✓ Release build completed: target/release/neoai_chat${NC}"
    else
        echo -e "${YELLOW}Building in debug mode...${NC}"
        cargo build
        echo -e "${GREEN}✓ Debug build completed: target/debug/neoai_chat${NC}"
    fi
else
    echo -e "${RED}Error: Cargo not found. Please install Rust and Cargo.${NC}"
    echo -e "${YELLOW}Visit: https://rustup.rs/${NC}"
    exit 1
fi

# Show build info
echo -e "${GREEN}Build Summary:${NC}"
echo -e "  - Application: NeoAI Chat"
echo -e "  - Icon: $([ -f "icon.png" ] && echo "✓ Present" || echo "⚠ Using fallback")"
echo -e "  - HTML: $([ -f "index.html" ] && echo "✓ Present" || echo "✗ Missing")"
echo -e "  - Assets: $([ -d "assets" ] && echo "✓ Directory exists" || echo "✗ Missing")"

if [ "$1" = "--release" ]; then
    echo -e "${GREEN}To run the application: ./target/release/neoai_chat${NC}"
else
    echo -e "${GREEN}To run the application: ./target/debug/neoai_chat${NC}"
fi

echo -e "${GREEN}Build completed successfully!${NC}"
