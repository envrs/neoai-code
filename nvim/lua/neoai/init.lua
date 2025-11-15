-- NeoAI main module
-- Entry point for the NeoAI plugin

local M = {}

-- Setup function
function M.setup(opts)
  -- Load configuration
  local config = require("neoai.config")
  if opts then
    config.set_config(opts)
  end
  
  -- Setup modules
  local modules = {
    "neoai.auto_commands",
    "neoai.keymaps",
    "neoai.workspace",
    "neoai.chat",
  }
  
  for _, module in ipairs(modules) do
    local ok, mod = pcall(require, module)
    if ok and mod.setup then
      mod.setup()
    end
  end
  
  -- Initialize logging
  local logging = require("neoai.logging")
  logging.configure({
    level = opts and opts.log_level or "INFO",
    file_enabled = true,
    console_enabled = true,
  })
  
  logging.info("NeoAI plugin initialized")
end

-- Expose main modules
M.chat = require("neoai.chat")
M.complete = require("neoai.completion")
M.config = require("neoai.config")
M.workspace = require("neoai.workspace")
M.utils = require("neoai.utils")

return M
