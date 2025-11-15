#!/bin/bash

# run-local-repo.sh - Creates a web server to serve locally built IntelliJ plugins
# This script sets up a plugin repository that JetBrains IDEs can recognize

set -e

# Configuration
SCRIPT_DIR="$(dirname "$0")"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
LOCAL_REPO_DIR="$SCRIPT_DIR"
BUILD_DIR="$PLUGIN_DIR/build/distributions"
PORT=${1:-8080}
HOST=${2:-localhost}

echo "🚀 Starting local IntelliJ plugin repository server..."
echo "📁 Plugin directory: $PLUGIN_DIR"
echo "🌐 Local repo directory: $LOCAL_REPO_DIR"
echo "🔨 Build directory: $BUILD_DIR"
echo "🌍 Server will run on: http://$HOST:$PORT"

# Check if build directory exists and has plugin files
if [ ! -d "$BUILD_DIR" ]; then
    echo "❌ Build directory not found. Please build the plugin first:"
    echo "   cd $PLUGIN_DIR && ./gradlew buildPlugin"
    exit 1
fi

# Find the built plugin zip file
PLUGIN_ZIP=$(find "$BUILD_DIR" -name "*.zip" | head -n 1)
if [ -z "$PLUGIN_ZIP" ]; then
    echo "❌ No plugin zip file found in $BUILD_DIR"
    echo "   Please build the plugin first: ./gradlew buildPlugin"
    exit 1
fi

PLUGIN_NAME=$(basename "$PLUGIN_ZIP" .zip)
echo "📦 Found plugin: $PLUGIN_NAME"

# Create local repository structure
mkdir -p "$LOCAL_REPO_DIR"

# Copy plugin to local repo
cp "$PLUGIN_ZIP" "$LOCAL_REPO_DIR/"
echo "✅ Copied plugin to local repository"

# Extract plugin metadata
PLUGIN_XML_PATH="$LOCAL_REPO_DIR/$PLUGIN_NAME/plugin.xml"
if [ -f "$PLUGIN_ZIP" ]; then
    unzip -p "$PLUGIN_ZIP" "*/plugin.xml" > "$PLUGIN_XML_PATH" 2>/dev/null || {
        echo "⚠️  Could not extract plugin.xml from zip"
    }
fi

# Generate plugins.xml repository index
generate_plugins_xml() {
    local plugin_file="$1"
    local plugin_name=$(basename "$plugin_file" .zip)
    local plugin_size=$(stat -f%z "$plugin_file" 2>/dev/null || stat -c%s "$plugin_file" 2>/dev/null || echo "0")
    local download_url="http://$HOST:$PORT/$plugin_name.zip"
    
    # Extract version from plugin.xml if available
    local version="1.0.0"
    if [ -f "$PLUGIN_XML_PATH" ]; then
        version=$(grep -o '<version[^>]*>[^<]*</version>' "$PLUGIN_XML_PATH" | sed 's/<version[^>]*>//;s/<\/version>//' | head -n 1 || echo "1.0.0")
    fi
    
    cat > "$LOCAL_REPO_DIR/plugins.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<plugins>
    <plugin id="com.neoai.assistant" url="$download_url" version="$version">
        <name>NeoAI Assistant</name>
        <description>AI-powered code completion and assistance for IntelliJ IDEA.</description>
        <version>$version</version>
        <vendor email="support@neoai.com" url="https://neoai.com">NeoAI</vendor>
        <idea-version since-build="232" until-build="242.*"/>
        <depends>com.intellij.java</depends>
    </plugin>
</plugins>
EOF
}

generate_plugins_xml "$PLUGIN_ZIP"
echo "✅ Generated plugins.xml repository index"

# Create a simple HTTP server
start_server() {
    echo "🌐 Starting HTTP server on http://$HOST:$PORT"
    echo "📋 Repository URL: http://$HOST:$PORT/plugins.xml"
    echo ""
    echo "To use this repository in IntelliJ:"
    echo "1. Open IntelliJ IDEA"
    echo "2. Go to File > Settings > Plugins"
    echo "3. Click the gear icon ⚙️ and select 'Manage Plugin Repositories...'"
    echo "4. Add: http://$HOST:$PORT/plugins.xml"
    echo "5. Click OK and search for 'NeoAI Assistant'"
    echo ""
    echo "Press Ctrl+C to stop the server"
    echo ""
    
    cd "$LOCAL_REPO_DIR"
    
    # Try different Python servers
    if command -v python3 &> /dev/null; then
        python3 -m http.server "$PORT" --bind "$HOST"
    elif command -v python &> /dev/null; then
        python -m SimpleHTTPServer "$PORT" 2>/dev/null || python -m http.server "$PORT" --bind "$HOST"
    elif command -v node &> /dev/null; then
        echo "Using Node.js server..."
        node -e "
const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const server = http.createServer((req, res) => {
    const parsedUrl = url.parse(req.url);
    let filePath = path.join('.', parsedUrl.pathname);
    
    if (filePath === './') filePath = './plugins.xml';
    
    fs.readFile(filePath, (err, data) => {
        if (err) {
            res.writeHead(404);
            res.end('File not found');
            return;
        }
        
        const ext = path.extname(filePath);
        const contentType = ext === '.xml' ? 'application/xml' : 'application/zip';
        
        res.writeHead(200, { 'Content-Type': contentType });
        res.end(data);
    });
});

server.listen($PORT, '$HOST', () => {
    console.log(\`Server running at http://$HOST:$PORT/\`);
});
        "
    else
        echo "❌ No suitable HTTP server found (Python3, Python, or Node.js required)"
        exit 1
    fi
}

# Check if port is already in use
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "⚠️  Port $PORT is already in use. Trying alternative ports..."
    for alt_port in {8081..8090}; do
        if ! lsof -Pi :$alt_port -sTCP:LISTEN -t >/dev/null 2>&1; then
            PORT=$alt_port
            echo "✅ Using port $PORT"
            break
        fi
    done
fi

start_server
