-- Basic NeoAI Setup Example
-- This demonstrates the minimal configuration needed to get started

require("neoai").setup({
  -- Your API key (can also be set via environment variable NEOAI_API_KEY)
  api_key = "your-api-key-here",
  
  -- Model to use for completions and chat
  model = "gpt-3.5-turbo",
  
  -- Enable main features
  features = {
    chat_interface = true,
    auto_complete = true,
    workspace_integration = true,
    lsp_integration = true,
  },
})

-- Basic keymaps will be automatically set up:
-- <leader>ac - Open chat interface
-- <leader>as - Show status
-- <C-g> (insert mode) - Trigger completion
