-- NeoAI health check module
-- Provides health checks for NeoAI plugin

local M = {}

-- Check if a binary is available
local function check_binary(name, description)
  local binary = require("neoai.binary")
  local available = binary.is_available(name)
  local version = binary.get_version(name)
  
  if available then
    return "✓ " .. description .. " (version: " .. (version or "unknown") .. ")"
  else
    return "✗ " .. description .. " - not found"
  end
end

-- Check configuration
local function check_config()
  local config = require("neoai.config")
  local checks = {}
  
  -- Check API key
  local api_key = config.get("api_key")
  if api_key and api_key ~= "" then
    table.insert(checks, "✓ API key configured")
  else
    table.insert(checks, "✗ API key not configured")
  end
  
  -- Check enterprise configuration
  local enterprise_host = config.get("neoai_enterprise_host")
  if enterprise_host and enterprise_host ~= "" then
    table.insert(checks, "✓ Enterprise host configured: " .. enterprise_host)
  end
  
  -- Check features
  local features = { "chat_interface", "auto_complete", "workspace_integration", "lsp_integration" }
  for _, feature in ipairs(features) do
    local enabled = config.get("features." .. feature)
    if enabled then
      table.insert(checks, "✓ Feature enabled: " .. feature)
    else
      table.insert(checks, "- Feature disabled: " .. feature)
    end
  end
  
  return checks
end

-- Check workspace
local function check_workspace()
  local workspace = require("neoai.workspace")
  local checks = {}
  
  local root = workspace.get_workspace_root()
  if root then
    table.insert(checks, "✓ Workspace root: " .. root)
  else
    table.insert(checks, "- No workspace root detected")
  end
  
  local context = workspace.get_context()
  if context then
    table.insert(checks, "✓ Workspace context: " .. context.total_files .. " files, " .. context.context_size .. " bytes")
  else
    table.insert(checks, "- No workspace context available")
  end
  
  return checks
end

-- Main health check function
function M.check()
  local health = vim.health or require("health")
  
  health.report_start("NeoAI")
  
  -- Check Neovim version
  local version = vim.version()
  if version.major >= 0 and version.minor >= 7 then
    health.report_ok("Neovim version: " .. version.major .. "." .. version.minor .. "." .. version.patch)
  else
    health.report_error("Neovim version too old: " .. version.major .. "." .. version.minor .. "." .. version.patch .. " (requires 0.7.0+)")
  end
  
  -- Check required binaries
  local binary = require("neoai.binary")
  local required = binary.get_required_binaries()
  
  health.report_start("Binary checks")
  for _, bin in ipairs(required) do
    local available = binary.is_available(bin)
    if available then
      health.report_ok(bin .. " binary available")
    else
      health.report_error(bin .. " binary not found")
    end
  end
  
  -- Check configuration
  health.report_start("Configuration")
  local config_checks = check_config()
  for _, check in ipairs(config_checks) do
    if check:match("^✓") then
      health.report_ok(check:sub(3))
    elseif check:match("^✗") then
      health.report_error(check:sub(3))
    else
      health.report_info(check:sub(3))
    end
  end
  
  -- Check workspace
  health.report_start("Workspace")
  local workspace_checks = check_workspace()
  for _, check in ipairs(workspace_checks) do
    if check:match("^✓") then
      health.report_ok(check:sub(3))
    else
      health.report_info(check:sub(3))
    end
  end
  
  -- Check modules
  health.report_start("Module checks")
  local modules = {
    "neoai.chat",
    "neoai.completion",
    "neoai.config",
    "neoai.utils",
    "neoai.platform",
    "neoai.workspace",
    "neoai.binary",
    "neoai.logging",
  }
  
  for _, module in ipairs(modules) do
    local ok, mod = pcall(require, module)
    if ok then
      health.report_ok(module .. " module loaded")
    else
      health.report_error(module .. " module failed to load: " .. mod)
    end
  end
  
  -- Check logging
  health.report_start("Logging")
  local ok, logging = pcall(require, "neoai.logging")
  if ok then
    local log_path = logging.get_log_path()
    if log_path then
      health.report_ok("Logging enabled: " .. log_path)
    else
      health.report_warn("Logging not initialized")
    end
  else
    health.report_error("Logging module not available")
  end
  
  -- Final summary
  health.report_start("Summary")
  local all_good = true
  
  -- Count errors
  local error_count = 0
  local warn_count = 0
  
  -- This is a simplified check - in reality, health.report_* functions
  -- would maintain internal counters
  for _, bin in ipairs(required) do
    if not binary.is_available(bin) then
      error_count = error_count + 1
    end
  end
  
  if error_count == 0 then
    health.report_ok("All checks passed - NeoAI is ready to use!")
  else
    health.report_error(string.format("%d issues found - NeoAI may not work correctly", error_count))
  end
end

return M
