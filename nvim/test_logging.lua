#!/usr/bin/env lua

-- Test script for NeoAI logging functionality

-- Add the lua directory to the package path
package.path = package.path .. ";lua/?.lua;lua/?/init.lua"

-- Mock vim functions for testing
if not vim then
  vim = {
    fn = {
      isdirectory = function(path) return 1 end,
      filereadable = function(path) return 0 end,
      getftime = function(path) return os.time() end,
      getfsize = function(path) return 1024 end,
    },
    log = {
      levels = {
        TRACE = 0,
        DEBUG = 1,
        INFO = 2,
        WARN = 3,
        ERROR = 4,
        OFF = 5,
      }
    },
    notify = function(msg, level) print("[NOTIFY] " .. msg) end,
  }
end

-- Test the logging module
print("Testing NeoAI Logging Module...")
print("===============================")

-- Load modules
local platform = require("neoai.platform")
local logging = require("neoai.logging")

-- Test 1: Platform detection
print("\n1. Platform Information:")
local info = platform.get_platform_info()
for key, value in pairs(info) do
  print(string.format("  %s: %s", key, tostring(value)))
end

-- Test 2: Initialize logging
print("\n2. Initializing Logging...")
logging.init({
  level = "DEBUG",
  file = true,
  console = true,
  max_file_size = 1024 * 1024, -- 1MB for testing
  max_files = 3,
})

-- Test 3: Log at different levels
print("\n3. Testing Log Levels:")
logging.trace("This is a TRACE message")
logging.debug("This is a DEBUG message")
logging.info("This is an INFO message")
logging.warn("This is a WARN message")
logging.error("This is an ERROR message")

-- Test 4: Logging with context
print("\n4. Testing Context Logging:")
logging.info("Test with context", {
  user = "test_user",
  action = "test_logging",
  timestamp = os.date("%Y-%m-%d %H:%M:%S"),
})

-- Test 5: Log file operations
print("\n5. Testing Log File Operations:")
local log_path = logging.get_log_path()
print("  Log path: " .. (log_path or "nil"))

-- Test tail
local tail_lines = logging.tail_log_file(5)
print("  Last 5 lines:")
for i, line in ipairs(tail_lines) do
  print(string.format("    %d: %s", i, line))
end

-- Test search
local search_results = logging.search_log("INFO")
print("  Search results for 'INFO': " .. #search_results .. " matches")
for i, result in ipairs(search_results) do
  if i <= 3 then -- Show first 3 results
    print(string.format("    Line %d: %s", result.line_number, result.content))
  end
end

-- Test 6: Log information
print("\n6. Log Information:")
local log_info = logging.get_log_info()
for key, value in pairs(log_info) do
  if type(value) == "table" then
    print(string.format("  %s: [%d entries]", key, #value))
  else
    print(string.format("  %s: %s", key, tostring(value)))
  end
end

-- Test 7: Log level changes
print("\n7. Testing Log Level Changes:")
print("  Current level: " .. logging._get_level_name(logging.get_level()))
logging.set_level("ERROR")
print("  Set to ERROR, current: " .. logging._get_level_name(logging.get_level()))
logging.info("This INFO should not appear")
logging.error("This ERROR should appear")
logging.set_level("INFO")
print("  Reset to INFO, current: " .. logging._get_level_name(logging.get_level()))

-- Test 8: Performance logging
print("\n8. Testing Performance Logging:")
local start_time = os.clock()
for i = 1, 100 do
  logging.debug(string.format("Performance test iteration %d", i))
end
local elapsed = os.clock() - start_time
print(string.format("  Logged 100 messages in %.4f seconds", elapsed))

print("\n===============================")
print("Logging test completed!")
print("Check the log file at: " .. (log_path or "nil"))
