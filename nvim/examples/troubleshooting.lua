-- Troubleshooting and Debugging Examples
-- This demonstrates how to diagnose and fix common NeoAI issues

require("neoai").setup({
  api_key = "your-api-key-here",
  debug = true,  -- Enable debug mode for troubleshooting
})

-- Troubleshooting utilities
local troubleshoot = {}

-- Check all plugin dependencies
function troubleshoot.check_dependencies()
  local required_binaries = { "curl", "git" }
  local missing = {}
  
  for _, binary in ipairs(required_binaries) do
    if vim.fn.executable(binary) == 0 then
      table.insert(missing, binary)
    end
  end
  
  if #missing > 0 then
    print("❌ Missing required binaries: " .. table.concat(missing, ", "))
    print("Install them with:")
    if vim.fn.has("mac") == 1 then
      print("  brew install " .. table.concat(missing, " "))
    elseif vim.fn.has("unix") == 1 then
      print("  sudo apt-get install " .. table.concat(missing, " "))
    end
  else
    print("✅ All required binaries are available")
  end
end

-- Check API configuration
function troubleshoot.check_api_config()
  local config = require("neoai.config")
  local api_key = config.get("api_key")
  
  if not api_key or api_key == "" then
    print("❌ API key not configured")
    print("Set it in your config or via NEOAI_API_KEY environment variable")
    return false
  else
    print("✅ API key is configured")
    return true
  end
end

-- Check binary availability
function troubleshoot.check_binary()
  local chat = require("neoai.chat")
  
  if not chat.enabled then
    print("❌ Chat interface is disabled (Pro feature)")
    return false
  end
  
  if not chat.available() then
    print("❌ NeoAI chat binary not found")
    print("Build it with: `cargo build --release` inside the `chat/` directory")
    return false
  else
    print("✅ NeoAI chat binary is available")
    return true
  end
end

-- Check workspace detection
function troubleshoot.check_workspace()
  local workspace = require("neoai.workspace")
  local stats = workspace.get_statistics()
  
  if stats.total_files == 0 then
    print("❌ No workspace detected or no files found")
    print("Make sure you're in a valid project directory")
    return false
  else
    print("✅ Workspace detected with " .. stats.total_files .. " files")
    return true
  end
end

-- Check LSP integration
function troubleshoot.check_lsp()
  local lsp = require("neoai.lsp")
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_active_clients({ bufnr = bufnr })
  
  if #clients == 0 then
    print("❌ No LSP clients attached to current buffer")
    print("Set up LSP for your language server")
    return false
  else
    print("✅ LSP clients attached: " .. #clients)
    for _, client in ipairs(clients) do
      print("  - " .. client.name)
    end
    return true
  end
end

-- Check completion status
function troubleshoot.check_completion()
  local state = require("neoai.state")
  local utils = require("neoai.utils")
  local config = require("neoai.config")
  
  print("Completion Status:")
  print("  Active: " .. tostring(state.active))
  print("  Should complete: " .. tostring(require("neoai.completion").should_complete()))
  print("  Filetype excluded: " .. tostring(vim.tbl_contains(config.get_config().exclude_filetypes, vim.bo.filetype)))
  print("  Document changed: " .. tostring(utils.document_changed()))
end

-- Run comprehensive health check
function troubleshoot.full_health_check()
  print("NeoAI Health Check")
  print("==================")
  
  local checks = {
    { name = "Dependencies", func = troubleshoot.check_dependencies },
    { name = "API Configuration", func = troubleshoot.check_api_config },
    { name = "Binary Availability", func = troubleshoot.check_binary },
    { name = "Workspace Detection", func = troubleshoot.check_workspace },
    { name = "LSP Integration", func = troubleshoot.check_lsp },
  }
  
  local all_passed = true
  for _, check in ipairs(checks) do
    print("\n" .. check.name .. ":")
    local result = check.func()
    all_passed = all_passed and (result ~= false)
  end
  
  print("\nCompletion Status:")
  troubleshoot.check_completion()
  
  print("\n" .. string.rep("=", 20))
  if all_passed then
    print("✅ All checks passed!")
  else
    print("❌ Some checks failed. See above for details.")
  end
end

-- Test API connection
function troubleshoot.test_api_connection()
  local neoai_binary = require("neoai.binary")
  
  print("Testing API connection...")
  neoai_binary:request({
    Test = { message = "Hello, NeoAI!" }
  }, function(response)
    if response and response.success then
      print("✅ API connection successful")
    else
      print("❌ API connection failed")
      print("Check your API key and network connection")
    end
  end)
end

-- Generate debug report
function troubleshoot.generate_debug_report()
  local report = {
    neoai_version = "1.0.0",  -- This should be dynamically determined
    nvim_version = vim.fn.execute("version"):match("NVIM v(%S+)"),
    os = vim.fn.has("mac") == 1 and "macOS" or 
         vim.fn.has("unix") == 1 and "Linux" or "Windows",
    config = require("neoai.config").get_config(),
    workspace_stats = require("neoai.workspace").get_statistics(),
    current_file = vim.fn.expand("%:p"),
    current_filetype = vim.bo.filetype,
  }
  
  local report_file = vim.fn.stdpath("cache") .. "/neoai_debug_report.json"
  local json = vim.json.encode(report)
  vim.fn.writefile(vim.split(json, "\n"), report_file)
  
  print("Debug report generated: " .. report_file)
end

-- Reset NeoAI configuration
function troubleshoot.reset_config()
  local config = require("neoai.config")
  config.set_config({})  -- Reset to defaults
  print("NeoAI configuration reset to defaults")
end

-- Reload NeoAI plugin
function troubleshoot.reload_plugin()
  -- Clear all NeoAI modules
  for module, _ in pairs(package.loaded) do
    if module:match("^neoai") then
      package.loaded[module] = nil
    end
  end
  
  -- Reinitialize
  require("neoai").setup()
  print("NeoAI plugin reloaded")
end

-- Set up troubleshooting keymaps
vim.keymap.set("n", "<leader>th", troubleshoot.full_health_check,
  { desc = "NeoAI: Health Check" })

vim.keymap.set("n", "<leader>td", troubleshoot.generate_debug_report,
  { desc = "NeoAI: Generate Debug Report" })

vim.keymap.set("n", "<leader>tr", troubleshoot.reload_plugin,
  { desc = "NeoAI: Reload Plugin" })

vim.keymap.set("n", "<leader>treset", troubleshoot.reset_config,
  { desc = "NeoAI: Reset Config" })

vim.keymap.set("n", "<leader>ttest", troubleshoot.test_api_connection,
  { desc = "NeoAI: Test API Connection" })

-- Troubleshooting commands
vim.api.nvim_create_user_command("NeoaiHealth", troubleshoot.full_health_check, {})
vim.api.nvim_create_user_command("NeoaiDebug", troubleshoot.generate_debug_report, {})
vim.api.nvim_create_user_command("NeoaiReload", troubleshoot.reload_plugin, {})

-- Auto-troubleshooting on errors
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    -- Run quick health check on startup
    vim.defer_fn(function()
      local api_ok = troubleshoot.check_api_config()
      local binary_ok = troubleshoot.check_binary()
      
      if not api_ok or not binary_ok then
        print("\nNeoAI issues detected. Run :NeoaiHealth for details")
      end
    end, 2000)
  end,
})

-- Logging utilities for debugging
local function setup_debug_logging()
  local logging = require("neoai.logging")
  
  -- Enable verbose logging
  logging.configure({
    level = "DEBUG",
    file_enabled = true,
    console_enabled = true,
    file_path = vim.fn.stdpath("cache") .. "/neoai_debug.log",
  })
  
  -- Custom logging function
  _G.neoai_debug = function(message)
    logging.debug("[CUSTOM] " .. message)
  end
end

-- Enable debug logging if debug mode is on
if require("neoai.config").get("debug") then
  setup_debug_logging()
end
