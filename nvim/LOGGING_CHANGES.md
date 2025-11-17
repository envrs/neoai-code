# NeoAI Logging Implementation

## Overview

This document summarizes the logging functionality added to the NeoAI Neovim plugin. The logging system provides comprehensive debugging and monitoring capabilities with platform-aware file handling, log rotation, and multiple output destinations.

## Files Modified/Created

### 1. `/nvim/lua/neoai/platform.lua`
- Added `get_log_dir()` function to provide platform-specific log directory
- Updated `get_platform_info()` to include log directory

### 2. `/nvim/lua/neoai/logging.lua` (NEW)
- Complete logging module with:
  - Multiple log levels (TRACE, DEBUG, INFO, WARN, ERROR, OFF)
  - Console and file output
  - Automatic log rotation
  - Log search and tail functionality
  - Platform-aware log file paths
  - Performance optimization with buffering

### 3. `/nvim/plugin/neoai.lua`
- Added logging commands:
  - `:NeoAILogPath` - Show log file path
  - `:NeoAILogOpen` - Open log file in editor
  - `:NeoAILogLevel [LEVEL]` - Set or show log level
  - `:NeoAILogTail [N]` - Show last N lines of log
  - `:NeoAILogSearch <PATTERN>` - Search log for pattern
  - `:NeoAILogInfo` - Show log file information
  - `:NeoAILogExport [DEST]` - Export log to file

### 4. `/nvim/lua/neoai/health.lua`
- Added `check_logging()` function to verify logging setup
- Integrated logging check into main health check

### 5. `/nvim/doc/neoai.txt`
- Added logging section (8. LOGGING)
- Updated command list to include logging commands
- Added configuration examples

### 6. `/nvim/README.md`
- Added comprehensive logging section
- Updated Quick Reference with logging commands

### 7. `/nvim/test_logging.lua` (NEW)
- Test script to verify logging functionality
- Can be run standalone to test the logging module

## Features

### Log Levels
- **TRACE**: Most verbose, includes all function calls
- **DEBUG**: Debug information for development
- **INFO**: General information (default)
- **WARN**: Warning messages
- **ERROR**: Error messages only
- **OFF**: Disable logging

### Platform Support
- **Windows**: `%APPDATA%\NeoAI\logs`
- **macOS**: `~/Library/Caches/neoai/logs`
- **Linux**: `~/.cache/neoai/logs`

### Log Rotation
- Automatic rotation when file size exceeds limit (default: 10MB)
- Keeps specified number of log files (default: 5)
- Timestamped log file names (e.g., `neoai_2024-01-15_10-30-45.log`)

### Performance Features
- Buffered writes to reduce I/O operations
- Lazy log directory creation
- Efficient log search with line numbers
- Memory-efficient log tailing

## Configuration

```lua
require("neoai").setup({
  logging = {
    level = "INFO",           -- Log level
    file = true,              -- Enable file logging
    console = true,           -- Enable console logging
    max_file_size = 10485760, -- 10MB max file size
    max_files = 5,            -- Keep 5 log files
    log_file = "neoai.log",   -- Log file name
    log_dir = nil,            -- Auto-detect log directory
  },
})
```

## Usage Examples

### Basic Logging
```lua
local logging = require("neoai.logging")

-- Initialize with custom config
logging.init({
  level = "DEBUG",
  file = true,
  console = true,
})

-- Log messages
logging.info("Plugin initialized")
logging.warn("API rate limit approaching")
logging.error("Failed to connect to API")
```

### Logging with Context
```lua
logging.info("User action performed", {
  user = "john@example.com",
  action = "complete_code",
  buffer = vim.api.nvim_get_current_buf(),
  timestamp = os.time(),
})
```

### Performance Logging
```lua
local start = logging.start_timer()
-- ... perform operation ...
logging.duration("API request completed", start)
```

## Commands

| Command | Description |
|---------|-------------|
| `:NeoAILogPath` | Show current log file path |
| `:NeoAILogOpen` | Open log file in editor |
| `:NeoAILogLevel [LEVEL]` | Set or show log level |
| `:NeoAILogTail [N]` | Show last N lines (default: 50) |
| `:NeoAILogSearch <PATTERN>` | Search log for pattern |
| `:NeoAILogInfo` | Show log file information |
| `:NeoAILogExport [DEST]` | Export log to file |

## Health Check

The logging system is integrated with Neovim's health check system:

```vim
:checkhealth neoai
```

This will verify:
- Logging module availability
- Log directory existence
- Log file write permissions
- Current configuration

## Testing

Run the test script to verify logging functionality:

```bash
cd /path/to/neoai/nvim
lua test_logging.lua
```

## Integration Notes

The logging system is automatically initialized when NeoAI is set up. It uses the platform module to determine the appropriate log directory and handles all file operations in a platform-aware manner.

Log files are automatically rotated to prevent disk space issues, and the system includes performance optimizations to minimize impact on plugin performance.

## Troubleshooting

### Common Issues

1. **Log file not created**
   - Check if log directory exists and is writable
   - Verify logging is initialized
   - Run `:checkhealth neoai` for diagnostics

2. **Logs not appearing**
   - Check log level setting
   - Verify file logging is enabled
   - Check console logging setting

3. **Performance issues**
   - Increase `max_file_size` to reduce rotation frequency
   - Set higher log level to reduce output
   - Consider disabling console logging in production

### Debug Commands

```vim
" Show current log level
:NeoAILogLevel

" Show log file location
:NeoAILogPath

" Check recent logs
:NeoAILogTail 20

" Search for errors
:NeoAILogSearch ERROR
```
