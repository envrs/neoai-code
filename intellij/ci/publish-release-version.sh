#!/bin/bash

# Enable stacktrace reporting
set -e
trap 'echo "Error occurred at line $LINENO. Command: $BASH_COMMAND"' ERR

# Function to print stacktrace
print_stacktrace() {
    local frame=0
    echo "Stacktrace:"
    while caller $frame; do
        ((frame++))
    done
}

# Enhanced error handler with stacktrace
error_handler() {
    local exit_code=$?
    echo "Script failed with exit code $exit_code"
    print_stacktrace
    exit $exit_code
}

trap error_handler ERR

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSION_FILE="$PROJECT_ROOT/gradle.properties"

echo "Starting publish release version process..."
echo "Project root: $PROJECT_ROOT"

# Check if version file exists
if [ ! -f "$VERSION_FILE" ]; then
    echo "Error: Version file not found at $VERSION_FILE"
    exit 1
fi

# Read current version
CURRENT_VERSION=$(grep "version=" "$VERSION_FILE" | cut -d'=' -f2)
echo "Current version: $CURRENT_VERSION"

# Validate version format
if [[ ! $CURRENT_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid version format. Expected x.y.z"
    exit 1
fi

# Function to publish release
publish_release() {
    echo "Publishing release version $CURRENT_VERSION..."
    
    cd "$PROJECT_ROOT"
    
    # Clean and build
    echo "Cleaning and building project..."
    ./gradlew clean build -x test
    
    # Publish to repository
    echo "Publishing to repository..."
    ./gradlew publishToMavenLocal
    
    # Create Git tag
    echo "Creating Git tag v$CURRENT_VERSION..."
    git tag -a "v$CURRENT_VERSION" -m "Release version $CURRENT_VERSION"
    
    # Push tag
    echo "Pushing tag to remote..."
    git push origin "v$CURRENT_VERSION"
    
    echo "Release $CURRENT_VERSION published successfully!"
}

# Main execution
main() {
    echo "=== Publish Release Version Script ==="
    echo "Version: $CURRENT_VERSION"
    echo "Timestamp: $(date)"
    
    # Confirm before proceeding
    read -p "Do you want to publish release version $CURRENT_VERSION? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        publish_release
    else
        echo "Publishing cancelled by user"
        exit 0
    fi
}

# Run main function
main "$@"
