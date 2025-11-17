-- Custom Keymaps Example
-- This demonstrates how to set up custom keymaps for NeoAI

require("neoai").setup({
  api_key = "your-api-key-here",
  
  -- Disable default keymaps to create your own
  keymaps = {
    enabled = false,  -- Disable all default keymaps
  },
})

-- Set up your own custom keymaps
local neoai = require("neoai")

-- Chat interface keymaps
vim.keymap.set("n", "<leader>aa", function()
  neoai.chat.toggle()
end, { desc = "NeoAI: Toggle Chat" })

vim.keymap.set("n", "<leader>an", function()
  neoai.chat.new_conversation()
end, { desc = "NeoAI: New Conversation" })

vim.keymap.set("n", "<leader>ac", function()
  neoai.chat.clear_conversation()
end, { desc = "NeoAI: Clear Conversation" })

-- Completion keymaps
vim.keymap.set("i", "<C-;>", function()
  require("neoai.completion").trigger()
end, { desc = "NeoAI: Trigger Completion" })

vim.keymap.set("i", "<C-Enter>", function()
  require("neoai.completion").accept()
end, { desc = "NeoAI: Accept Completion" })

vim.keymap.set("i", "<C-Esc>", function()
  require("neoai.completion").clear()
end, { desc = "NeoAI: Clear Completion" })

-- Status and info keymaps
vim.keymap.set("n", "<leader>as", function()
  neoai.status()
end, { desc = "NeoAI: Show Status" })

vim.keymap.set("n", "<leader>aw", function()
  local context = neoai.get_context({
    max_files = 20,
    max_content = 5000,
  })
  print("Workspace context: " .. vim.inspect(context))
end, { desc = "NeoAI: Show Workspace Context" })

-- LSP integration keymaps
vim.keymap.set("n", "<leader>al", function()
  require("neoai.lsp").get_document_symbols(0)
end, { desc = "NeoAI: Get Document Symbols" })

-- Toggle features
vim.keymap.set("n", "<leader>atc", function()
  -- Toggle chat interface
  local config = require("neoai.config")
  local current = config.get("features.chat_interface")
  config.set("features.chat_interface", not current)
  print("Chat interface: " .. (not current and "enabled" or "disabled"))
end, { desc = "NeoAI: Toggle Chat" })

vim.keymap.set("n", "<leader>ata", function()
  -- Toggle auto completion
  local config = require("neoai.config")
  local current = config.get("features.auto_complete")
  config.set("features.auto_complete", not current)
  print("Auto completion: " .. (not current and "enabled" or "disabled"))
end, { desc = "NeoAI: Toggle Auto Complete" })
