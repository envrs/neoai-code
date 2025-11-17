-- NeoAI Quick Start Example
-- Copy this to your init.lua or include it in your Neovim config

-- Basic NeoAI setup with commonly used features
require("neoai").setup({
  -- Set your API key (recommended to use environment variable)
  api_key = os.getenv("NEOAI_API_KEY") or "your-api-key-here",
  
  -- Model selection
  model = "gpt-3.5-turbo",
  
  -- Enable main features
  features = {
    chat_interface = true,
    auto_complete = true,
    workspace_integration = true,
    lsp_integration = true,
  },
  
  -- Optimized completion settings
  completion = {
    trigger_length = 2,
    max_suggestions = 3,
    debounce_ms = 200,
    exclude_filetypes = {
      "gitcommit", "gitrebase", "svn", "hgcommit",
      "help", "man", "qf", "startify", "nerdtree", 
      "NvimTree", "neo-tree", "alpha", "dashboard",
      "TelescopePrompt", "WhichKey", "lspinfo",
      "checkhealth", "log", "markdown", "text", "rst",
    },
  },
  
  -- Chat interface settings
  chat = {
    max_messages = 50,
    context_lines = 20,
  },
  
  -- Essential keymaps (you can customize these)
  keymaps = {
    enabled = true,
    custom_keymaps = {
      -- Quick chat access
      {
        mode = "n",
        lhs = "<leader>ai",
        rhs = function()
          require("neoai.chat").toggle()
        end,
        opts = { desc = "NeoAI Chat", silent = true },
      },
      -- Send current file to chat
      {
        mode = "n",
        lhs = "<leader>af",
        rhs = function()
          local chat = require("neoai.chat")
          local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
          local content = table.concat(lines, "\n")
          local filename = vim.fn.expand("%:t")
          
          local message = string.format("Here's my %s file:\n\n```%s\n%s\n```", 
            filename, vim.bo.filetype, content)
          
          chat.submit_message(message)
          chat.open()
        end,
        opts = { desc = "NeoAI: Send File to Chat", silent = true },
      },
      -- Generate documentation
      {
        mode = "n",
        lhs = "<leader>ad",
        rhs = function()
          local chat = require("neoai.chat")
          local line = vim.fn.line(".")
          local lines = vim.api.nvim_buf_get_lines(0, line - 1, line + 10, false)
          local content = table.concat(lines, "\n")
          
          local message = string.format("Generate documentation for this code:\n\n```%s\n%s\n```", 
            vim.bo.filetype, content)
          
          chat.submit_message(message)
          chat.open()
        end,
        opts = { desc = "NeoAI: Generate Docs", silent = true },
      },
    },
  },
})

-- Essential utility functions
local M = {}

-- Quick health check
function M.health_check()
  print("NeoAI Quick Health Check:")
  
  -- Check API key
  local api_key = require("neoai.config").get("api_key")
  print("  API Key: " .. (api_key and "✅ Set" or "❌ Not set"))
  
  -- Check binary
  local chat = require("neoai.chat")
  print("  Chat Binary: " .. (chat.available() and "✅ Available" or "❌ Not found"))
  
  -- Check workspace
  local workspace = require("neoai.workspace")
  local stats = workspace.get_statistics()
  print("  Workspace: " .. stats.total_files .. " files")
  
  -- Check LSP
  local lsp_clients = vim.lsp.get_active_clients({ bufnr = 0 })
  print("  LSP Clients: " .. #lsp_clients)
end

-- Quick toggle functions
function M.toggle_completion()
  local state = require("neoai.state")
  state.active = not state.active
  print("Auto completion: " .. (state.active and "enabled" or "disabled"))
end

function M.toggle_chat()
  require("neoai.chat").toggle()
end

-- Quick commands
vim.api.nvim_create_user_command("NeoaiQuickHealth", M.health_check, 
  { desc = "NeoAI: Quick Health Check" })

vim.api.nvim_create_user_command("NeoaiToggleComplete", M.toggle_completion,
  { desc = "NeoAI: Toggle Completion" })

vim.api.nvim_create_user_command("NeoaiQuickChat", M.toggle_chat,
  { desc = "NeoAI: Toggle Chat" })

-- Essential keymaps for quick access
vim.keymap.set("n", "<leader>ah", M.health_check,
  { desc = "NeoAI: Health Check" })

vim.keymap.set("n", "<leader>at", M.toggle_completion,
  { desc = "NeoAI: Toggle Completion" })

vim.keymap.set("i", "<C-;>", function()
  require("neoai.completion").trigger()
end, { desc = "NeoAI: Trigger Completion" })

vim.keymap.set("i", "<C-Enter>", function()
  require("neoai.completion").accept()
end, { desc = "NeoAI: Accept Completion" })

vim.keymap.set("i", "<C-Esc>", function()
  require("neoai.completion").clear()
end, { desc = "NeoAI: Clear Completion" })

-- Auto-commands for common workflows
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "python", "javascript", "typescript", "lua", "rust", "go" },
  callback = function()
    -- Optimize settings for programming languages
    local config = require("neoai.config")
    config.set("completion.trigger_length", 2)
    config.set("completion.debounce_ms", 150)
  end,
})

-- Welcome message on first startup
vim.defer_fn(function()
  local api_key = require("neoai.config").get("api_key")
  if not api_key then
    print("NeoAI: API key not set. Set NEOAI_API_KEY environment variable or configure in setup()")
  else
    print("NeoAI: Ready! Use <leader>ai for chat, <C-;> for completion")
  end
end, 2000)

return M
