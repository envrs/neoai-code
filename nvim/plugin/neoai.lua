-- NeoAI plugin registration
-- This file handles plugin initialization and documentation registration

-- Check Vim version early
local ok, consts = pcall(require, "neoai.consts")
if ok then
  local version = vim.version()
  local required = consts.MIN_VIM_VERSION
  
  if version.major < required.major or 
     (version.major == required.major and version.minor < required.minor) then
    vim.notify(string.format(
      "NeoAI requires Vim >= %d.%d, but you have %d.%d.\n" ..
      "Please upgrade Vim: https://www.vim.org/download.php",
      required.major, required.minor,
      version.major, version.minor
    ), vim.log.levels.ERROR)
    return -- Stop loading plugin
  end
end

-- Register documentation
vim.opt.runtimepath:append(vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h"))

-- Register health check
if vim.health and vim.health.register then
  vim.health.register("neoai", require("neoai.health").check)
elseif vim.fn.has("nvim-0.4.0") == 1 then
  -- Use legacy health check for older Neovim
  vim.cmd("command! CheckHealth lua require('neoai.health').check()")
end

-- Setup autocommands
local neoai_group = vim.api.nvim_create_augroup("NeoAI", { clear = true })

vim.api.nvim_create_autocmd("VimEnter", {
  group = neoai_group,
  callback = function()
    -- Auto-initialize if not already done
    if not vim.g.neoai_initialized then
      local ok, neoai = pcall(require, "neoai")
      if ok and neoai.setup then
        neoai.setup()
        vim.g.neoai_initialized = true
      end
    end
  end,
  desc = "Auto-initialize NeoAI",
})

-- Register commands
vim.api.nvim_create_user_command("NeoAIChat", function()
  local ok, chat = pcall(require, "neoai.chat")
  if ok then
    chat.open()
  else
    vim.notify("NeoAI chat not available", vim.log.levels.ERROR)
  end
end, { desc = "Open NeoAI chat interface" })

vim.api.nvim_create_user_command("NeoAIComplete", function()
  local ok, complete = pcall(require, "neoai.complete")
  if ok then
    complete.trigger()
  else
    vim.notify("NeoAI completion not available", vim.log.levels.ERROR)
  end
end, { desc = "Trigger NeoAI completion" })

vim.api.nvim_create_user_command("NeoAIWorkspace", function()
  local ok, workspace = pcall(require, "neoai.workspace")
  if ok then
    local context = workspace.get_context()
    vim.notify(string.format("Workspace: %d files, %d bytes context", 
      context.total_files, context.context_size), vim.log.levels.INFO)
  else
    vim.notify("NeoAI workspace not available", vim.log.levels.ERROR)
  end
end, { desc = "Show NeoAI workspace info" })

vim.api.nvim_create_user_command("NeoAIConfig", function()
  local config_path = require("neoai.utils").get_config_file_path("config.json")
  vim.cmd("edit " .. config_path)
end, { desc = "Open NeoAI configuration file" })

vim.api.nvim_create_user_command("NeoAIToggle", function(opts)
  local feature = opts.args
  if feature == "" then
    vim.notify("Usage: NeoAIToggle <feature>", vim.log.levels.ERROR)
    return
  end
  
  local ok, config = pcall(require, "neoai.config")
  if ok then
    local current = config.get("features." .. feature)
    config.set("features." .. feature, not current)
    vim.notify(string.format("Toggled %s: %s", feature, not current), vim.log.levels.INFO)
  else
    vim.notify("Cannot toggle feature", vim.log.levels.ERROR)
  end
end, { 
  desc = "Toggle NeoAI feature",
  nargs = 1,
  complete = function()
    return { "chat_interface", "auto_complete", "workspace_integration", "lsp_integration" }
  end,
})

vim.api.nvim_create_user_command("NeoAIStatus", function()
  local checks = {
    "Platform: " .. require("neoai.platform").get_platform_info().os,
    "API Key: " .. (require("neoai.config").get("api_key") and "configured" or "not configured"),
    "Workspace: " .. (require("neoai.workspace").get_workspace_root() or "not set"),
  }
  
  local binary = require("neoai.binary")
  local required = binary.get_required_binaries()
  for _, bin in ipairs(required) do
    table.insert(checks, string.format("%s: %s", bin, binary.is_available(bin) and "available" or "not found"))
  end
  
  vim.notify("NeoAI Status:\n" .. table.concat(checks, "\n"), vim.log.levels.INFO)
end, { desc = "Show NeoAI status" })

vim.api.nvim_create_user_command("NeoAIUpdate", function()
  local ok, workspace = pcall(require, "neoai.workspace")
  if ok then
    workspace.update_workspace_files()
    vim.notify("Workspace updated", vim.log.levels.INFO)
  else
    vim.notify("Cannot update workspace", vim.log.levels.ERROR)
  end
end, { desc = "Update NeoAI workspace files" })

vim.api.nvim_create_user_command("NeoAIClear", function()
  local utils = require("neoai.utils")
  local cache_dir = require("neoai.platform").get_cache_dir()
  
  -- Clear cache directory
  vim.fn.delete(cache_dir, "rf")
  vim.notify("Cache cleared", vim.log.levels.INFO)
end, { desc = "Clear NeoAI cache" })

-- Logging commands
vim.api.nvim_create_user_command("NeoAILogPath", function()
  local logging = require("neoai.logging")
  local log_path = logging.get_log_path()
  if log_path then
    vim.notify("Log file: " .. log_path, vim.log.levels.INFO)
  else
    vim.notify("Logging not initialized", vim.log.levels.WARN)
  end
end, { desc = "Show NeoAI log file path" })

vim.api.nvim_create_user_command("NeoAILogOpen", function()
  local logging = require("neoai.logging")
  if logging.open_log_file() then
    vim.notify("Opened log file", vim.log.levels.INFO)
  end
end, { desc = "Open NeoAI log file" })

vim.api.nvim_create_user_command("NeoAILogLevel", function(opts)
  local level = opts.args
  if level == "" then
    local logging = require("neoai.logging")
    vim.notify("Current log level: " .. logging._get_level_name(logging.get_level()), vim.log.levels.INFO)
    return
  end
  
  local logging = require("neoai.logging")
  if logging.set_level(level) then
    vim.notify("Log level set to " .. level, vim.log.levels.INFO)
  else
    vim.notify("Invalid log level: " .. level, vim.log.levels.ERROR)
  end
end, { 
  desc = "Set or show NeoAI log level",
  nargs = "?",
  complete = function()
    return { "TRACE", "DEBUG", "INFO", "WARN", "ERROR", "OFF" }
  end,
})

vim.api.nvim_create_user_command("NeoAILogTail", function(opts)
  local lines = tonumber(opts.args) or 50
  local logging = require("neoai.logging")
  local tail_lines = logging.tail_log_file(lines)
  
  if #tail_lines > 0 then
    -- Create a new buffer to show log tail
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, tail_lines)
    vim.api.nvim_buf_set_option(buf, "filetype", "log")
    vim.api.nvim_buf_set_name(buf, "NeoAI Log Tail")
    
    -- Open in a new window
    vim.cmd("split")
    vim.api.nvim_win_set_buf(0, buf)
    
    vim.notify("Showing last " .. #tail_lines .. " log lines", vim.log.levels.INFO)
  else
    vim.notify("No log entries found", vim.log.levels.WARN)
  end
end, { 
  desc = "Show last N lines of NeoAI log",
  nargs = "?",
})

vim.api.nvim_create_user_command("NeoAILogSearch", function(opts)
  local pattern = opts.args
  if pattern == "" then
    vim.notify("Usage: NeoAILogSearch <pattern>", vim.log.levels.ERROR)
    return
  end
  
  local logging = require("neoai.logging")
  local results = logging.search_log(pattern)
  
  if #results > 0 then
    -- Create a new buffer to show search results
    local buf = vim.api.nvim_create_buf(false, true)
    local lines = { "Search results for pattern: " .. pattern, "" }
    
    for _, result in ipairs(results) do
      table.insert(lines, string.format("Line %d: %s", result.line_number, result.content))
    end
    
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, "filetype", "log")
    vim.api.nvim_buf_set_name(buf, "NeoAI Log Search")
    
    -- Open in a new window
    vim.cmd("split")
    vim.api.nvim_win_set_buf(0, buf)
    
    vim.notify("Found " .. #results .. " matching log entries", vim.log.levels.INFO)
  else
    vim.notify("No log entries found for pattern: " .. pattern, vim.log.levels.WARN)
  end
end, { 
  desc = "Search NeoAI log for pattern",
  nargs = 1,
})

vim.api.nvim_create_user_command("NeoAILogInfo", function()
  local logging = require("neoai.logging")
  local info = logging.get_log_info()
  
  local lines = {
    "NeoAI Log Information:",
    "=====================",
    "",
    "Current log file: " .. (info.current_file or "Not set"),
    "Log directory: " .. (info.log_dir or "Not set"),
    "Log level: " .. (info.level or "Unknown"),
    "File logging: " .. (info.file_enabled and "Enabled" or "Disabled"),
    "Console logging: " .. (info.console_enabled and "Enabled" or "Disabled"),
    "Max file size: " .. (info.max_file_size and (info.max_file_size / (1024 * 1024)) .. " MB" or "Unknown"),
    "Max files: " .. (info.max_files or "Unknown"),
    "",
    "Log files:",
  }
  
  for _, file in ipairs(info.files or {}) do
    table.insert(lines, string.format("  %s (%s MB, modified: %s)", 
      file.name, file.size_mb, os.date("%Y-%m-%d %H:%M:%S", file.modified)))
  end
  
  if #info.files > 0 then
    table.insert(lines, "")
    table.insert(lines, "Total size: " .. string.format("%.2f MB", (info.total_size or 0) / (1024 * 1024)))
  end
  
  -- Display in a buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "filetype", "text")
  vim.api.nvim_buf_set_name(buf, "NeoAI Log Info")
  
  vim.cmd("split")
  vim.api.nvim_win_set_buf(0, buf)
end, { desc = "Show NeoAI log information" })

vim.api.nvim_create_user_command("NeoAILogExport", function(opts)
  local destination = opts.args
  if destination == "" then
    destination = vim.fn.input("Export log to: ", vim.fn.expand("~/neoai.log"))
  end
  
  local logging = require("neoai.logging")
  if logging.export_log(destination) then
    vim.notify("Log exported to: " .. destination, vim.log.levels.INFO)
  else
    vim.notify("Failed to export log", vim.log.levels.ERROR)
  end
end, { 
  desc = "Export NeoAI log to file",
  nargs = "?",
})

-- Register key mappings (optional, can be overridden by user)
local function setup_mappings()
  local opts = { noremap = true, silent = true }
  
  -- Chat interface
  vim.keymap.set("n", "<leader>ac", "<cmd>NeoAIChat<cr>", opts)
  
  -- Completion
  vim.keymap.set("i", "<C-x><C-a>", "<cmd>NeoAIComplete<cr>", opts)
  
  -- Workspace info
  vim.keymap.set("n", "<leader>aw", "<cmd>NeoAIWorkspace<cr>", opts)
  
  -- Status
  vim.keymap.set("n", "<leader>as", "<cmd>NeoAIStatus<cr>", opts)
end

-- Only continue if version is compatible
local ok, config = pcall(require, "neoai.config")
if ok and config.get("setup_mappings") ~= false then
  setup_mappings()
end
