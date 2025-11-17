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
BUILD_DIR="$PROJECT_ROOT/build/distributions"

echo "Starting GitHub release publishing process..."
echo "Project root: $PROJECT_ROOT"

# Check dependencies
check_dependencies() {
    echo "Checking dependencies..."
    
    if ! command -v gh &> /dev/null; then
        echo "Error: GitHub CLI (gh) is not installed"
        echo "Please install it from: https://cli.github.com/"
        exit 1
    fi
    
    if ! gh auth status &> /dev/null; then
        echo "Error: GitHub CLI is not authenticated"
        echo "Please run: gh auth login"
        exit 1
    fi
    
    echo "Dependencies check passed"
}

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

# Function to build project
build_project() {
    echo "Building project..."
    cd "$PROJECT_ROOT"
    
    # Clean and build
    ./gradlew clean build
    
    # Create distribution
    ./gradlew distZip
    
    echo "Build completed successfully"
}

# Function to create GitHub release
create_github_release() {
    local tag_name="v$CURRENT_VERSION"
    local release_title="Release $CURRENT_VERSION"
    
    echo "Creating GitHub release..."
    echo "Tag: $tag_name"
    echo "Title: $release_title"
    
    # Check if tag already exists
    if git rev-parse "$tag_name" >/dev/null 2>&1; then
        echo "Warning: Tag $tag_name already exists"
        read -p "Do you want to continue and update the existing release? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Release creation cancelled"
            exit 0
        fi
    fi
    
    # Create release notes
    local release_notes="Release $CURRENT_VERSION

$(git log --oneline --pretty=format:"- %s" "$(git describe --tags --abbrev=0 HEAD^)..HEAD" 2>/dev/null || echo "No changes since last release")"
    
    # Find distribution files
    local dist_files=()
    if [ -d "$BUILD_DIR" ]; then
        while IFS= read -r -d '' file; do
            dist_files+=("$file")
        done < <(find "$BUILD_DIR" -name "*.zip" -o -name "*.jar" -print0)
    fi
    
    echo "Found distribution files: ${dist_files[@]}"
    
    # Create GitHub release
    if [ ${#dist_files[@]} -gt 0 ]; then
        echo "Creating release with assets..."
        gh release create "$tag_name" \
            --title "$release_title" \
            --notes "$release_notes" \
            "${dist_files[@]}"
    else
        echo "Creating release without assets..."
        gh release create "$tag_name" \
            --title "$release_title" \
            --notes "$release_notes"
    fi
    
    echo "GitHub release created successfully!"
}

# Function to push tag to remote
push_tag() {
    local tag_name="v$CURRENT_VERSION"
    
    echo "Creating and pushing tag..."
    
    # Create local tag if it doesn't exist
    if ! git rev-parse "$tag_name" >/dev/null 2>&1; then
        git tag -a "$tag_name" -m "Release $CURRENT_VERSION"
    fi
    
    # Push tag to remote
    git push origin "$tag_name"
    
    echo "Tag pushed successfully"
}

# Main execution
main() {
    echo "=== Publish GitHub Release Script ==="
    echo "Version: $CURRENT_VERSION"
    echo "Timestamp: $(date)"
    
    # Check dependencies first
    check_dependencies
    
    # Confirm before proceeding
    read -p "Do you want to publish GitHub release for version $CURRENT_VERSION? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "GitHub release publishing cancelled by user"
        exit 0
    fi
    
    # Execute steps
    build_project
    push_tag
    create_github_release
    
    echo "=== GitHub Release Publishing Complete ==="
    echo "Release: https://github.com/$(git config --get remote.origin.url | sed 's/.*://;s/\.git$//')/releases/tag/v$CURRENT_VERSION"
}

# Run main function
main "$@"
