-- NeoAI logging module
-- Provides logging functionality for NeoAI plugin

local M = {}

-- Log levels
M.TRACE = 1
M.DEBUG = 2
M.INFO = 3
M.WARN = 4
M.ERROR = 5
M.OFF = 6

-- Default configuration
local config = {
  level = M.INFO,
  file_enabled = true,
  console_enabled = true,
  max_file_size = 10 * 1024 * 1024, -- 10MB
  max_files = 5,
}

-- State
local log_file_path = nil
local log_file_handle = nil
local current_level = M.INFO

-- Get log directory
local function get_log_dir()
  local platform = require("neoai.platform")
  local cache_dir = platform.get_cache_dir()
  return cache_dir .. "/logs"
end

-- Get log file path
local function get_log_file_path()
  if not log_file_path then
    local log_dir = get_log_dir()
    vim.fn.mkdir(log_dir, "p")
    log_file_path = log_dir .. "/neoai.log"
  end
  return log_file_path
end

-- Rotate log file if needed
local function rotate_log_file()
  local path = get_log_file_path()
  local size = vim.fn.getfsize(path)
  
  if size > config.max_file_size then
    -- Close current file
    if log_file_handle then
      log_file_handle:close()
      log_file_handle = nil
    end
    
    -- Rotate files
    for i = config.max_files - 1, 1, -1 do
      local old_file = path .. "." .. i
      local new_file = path .. "." .. (i + 1)
      if vim.fn.filereadable(old_file) == 1 then
        vim.fn.rename(old_file, new_file)
      end
    end
    
    -- Move current file to .1
    if vim.fn.filereadable(path) == 1 then
      vim.fn.rename(path, path .. ".1")
    end
  end
end

-- Open log file
local function open_log_file()
  if not config.file_enabled then
    return
  end
  
  local path = get_log_file_path()
  rotate_log_file()
  
  log_file_handle = io.open(path, "a")
  if not log_file_handle then
    vim.notify("NeoAI: Failed to open log file: " .. path, vim.log.levels.ERROR)
  end
end

-- Close log file
local function close_log_file()
  if log_file_handle then
    log_file_handle:close()
    log_file_handle = nil
  end
end

-- Format log message
local function format_message(level, message)
  local level_names = {
    [M.TRACE] = "TRACE",
    [M.DEBUG] = "DEBUG",
    [M.INFO] = "INFO",
    [M.WARN] = "WARN",
    [M.ERROR] = "ERROR",
  }
  
  local timestamp = os.date("%Y-%m-%d %H:%M:%S")
  local level_name = level_names[level] or "UNKNOWN"
  
  return string.format("[%s] %s: %s", timestamp, level_name, message)
end

-- Write log message
local function write_log(level, message)
  if level < current_level then
    return
  end
  
  local formatted = format_message(level, message)
  
  -- Write to console
  if config.console_enabled then
    local vim_level = vim.log.levels.INFO
    if level == M.WARN then
      vim_level = vim.log.levels.WARN
    elseif level == M.ERROR then
      vim_level = vim.log.levels.ERROR
    elseif level == M.DEBUG then
      vim_level = vim.log.levels.DEBUG
    end
    vim.notify(formatted, vim_level, { title = "NeoAI" })
  end
  
  -- Write to file
  if config.file_enabled then
    if not log_file_handle then
      open_log_file()
    end
    
    if log_file_handle then
      log_file_handle:write(formatted .. "\n")
      log_file_handle:flush()
    end
  end
end

-- Public API

-- Set log level
function M.set_level(level)
  if type(level) == "string" then
    level = level:upper()
    if level == "TRACE" then
      current_level = M.TRACE
    elseif level == "DEBUG" then
      current_level = M.DEBUG
    elseif level == "INFO" then
      current_level = M.INFO
    elseif level == "WARN" then
      current_level = M.WARN
    elseif level == "ERROR" then
      current_level = M.ERROR
    elseif level == "OFF" then
      current_level = M.OFF
    else
      return false
    end
  else
    current_level = level
  end
  return true
end

-- Get log level
function M.get_level()
  return current_level
end

-- Get level name (for internal use)
function M._get_level_name(level)
  local names = {
    [M.TRACE] = "TRACE",
    [M.DEBUG] = "DEBUG",
    [M.INFO] = "INFO",
    [M.WARN] = "WARN",
    [M.ERROR] = "ERROR",
    [M.OFF] = "OFF",
  }
  return names[level] or "UNKNOWN"
end

-- Log functions
function M.trace(message)
  write_log(M.TRACE, message)
end

function M.debug(message)
  write_log(M.DEBUG, message)
end

function M.info(message)
  write_log(M.INFO, message)
end

function M.warn(message)
  write_log(M.WARN, message)
end

function M.error(message)
  write_log(M.ERROR, message)
end

-- Get log file path
function M.get_log_path()
  return get_log_file_path()
end

-- Open log file in Neovim
function M.open_log_file()
  local path = get_log_file_path()
  if vim.fn.filereadable(path) == 1 then
    vim.cmd("edit " .. path)
    return true
  end
  return false
end

-- Tail log file
function M.tail_log_file(lines)
  lines = lines or 50
  local path = get_log_file_path()
  
  if vim.fn.filereadable(path) ~= 1 then
    return {}
  end
  
  local result = {}
  local file = io.open(path, "r")
  if not file then
    return {}
  end
  
  local all_lines = {}
  for line in file:lines() do
    table.insert(all_lines, line)
  end
  file:close()
  
  -- Get last N lines
  local start = math.max(1, #all_lines - lines + 1)
  for i = start, #all_lines do
    table.insert(result, all_lines[i])
  end
  
  return result
end

-- Search log file
function M.search_log(pattern)
  local path = get_log_file_path()
  
  if vim.fn.filereadable(path) ~= 1 then
    return {}
  end
  
  local result = {}
  local file = io.open(path, "r")
  if not file then
    return {}
  end
  
  local line_number = 0
  for line in file:lines() do
    line_number = line_number + 1
    if line:match(pattern) then
      table.insert(result, {
        line_number = line_number,
        content = line,
      })
    end
  end
  file:close()
  
  return result
end

-- Get log information
function M.get_log_info()
  local log_dir = get_log_dir()
  local info = {
    current_file = get_log_file_path(),
    log_dir = log_dir,
    level = M._get_level_name(current_level),
    file_enabled = config.file_enabled,
    console_enabled = config.console_enabled,
    max_file_size = config.max_file_size,
    max_files = config.max_files,
    files = {},
    total_size = 0,
  }
  
  -- Collect information about log files
  local files = vim.fn.glob(log_dir .. "/neoai.log*", false, true)
  for _, file in ipairs(files) do
    local stat = vim.loop.fs_stat(file)
    if stat then
      table.insert(info.files, {
        name = vim.fn.fnamemodify(file, ":t"),
        size_mb = stat.size / (1024 * 1024),
        modified = stat.mtime.sec,
      })
      info.total_size = info.total_size + stat.size
    end
  end
  
  return info
end

-- Export log file
function M.export_log(destination)
  local path = get_log_file_path()
  
  if vim.fn.filereadable(path) ~= 1 then
    return false
  end
  
  local content = vim.fn.readfile(path)
  local ok = pcall(vim.fn.writefile, content, destination)
  
  return ok
end

-- Configure logging
function M.configure(opts)
  if opts.level then
    M.set_level(opts.level)
  end
  
  if opts.file_enabled ~= nil then
    config.file_enabled = opts.file_enabled
    if not opts.file_enabled then
      close_log_file()
    end
  end
  
  if opts.console_enabled ~= nil then
    config.console_enabled = opts.console_enabled
  end
  
  if opts.max_file_size then
    config.max_file_size = opts.max_file_size
  end
  
  if opts.max_files then
    config.max_files = opts.max_files
  end
end

-- Initialize logging
function M.init()
  -- Set default log level based on Neovim's verbosity
  local v = vim.v.vim_did_enter and vim.opt.verbosity:get() or 0
  if v >= 2 then
    M.set_level(M.DEBUG)
  elseif v >= 1 then
    M.set_level(M.INFO)
  else
    M.set_level(M.WARN)
  end
  
  -- Clean shutdown
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      close_log_file()
    end,
    desc = "Close NeoAI log file on exit",
  })
end

-- Auto-initialize
M.init()

return M
