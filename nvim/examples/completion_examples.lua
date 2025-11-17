-- Auto Completion Examples
-- This demonstrates various completion scenarios and configurations

require("neoai").setup({
  api_key = "your-api-key-here",
  features = {
    auto_complete = true,
  },
  
  -- Fine-tuned completion settings
  completion = {
    trigger_length = 2,           -- Trigger after 2 characters
    max_suggestions = 3,           -- Show max 3 suggestions
    debounce_ms = 200,             -- Faster response
    exclude_filetypes = {
      "gitcommit", "gitrebase", "svn", "hgcommit",
      "help", "man", "qf", "startify",
      "TelescopePrompt", "WhichKey", "lspinfo",
    },
  },
})

-- Manual completion trigger function
local function trigger_completion()
  if require("neoai.completion").should_complete() then
    require("neoai.completion").trigger()
  else
    print("Completion not available for this filetype")
  end
end

-- Accept current completion
local function accept_completion()
  require("neoai.completion").accept()
end

-- Clear completion
local function clear_completion()
  require("neoai.completion").clear()
end

-- Toggle completion for current buffer
local function toggle_completion()
  local state = require("neoai.state")
  state.active = not state.active
  print("Auto completion: " .. (state.active and "enabled" or "disabled"))
end

-- Check if completion is available
local function check_completion_status()
  local state = require("neoai.state")
  local utils = require("neoai.utils")
  local config = require("neoai.config")
  
  print("Completion Status:")
  print("  Active: " .. tostring(state.active))
  print("  Document changed: " .. tostring(utils.document_changed()))
  print("  Filetype excluded: " .. tostring(vim.tbl_contains(config.get_config().exclude_filetypes, vim.bo.filetype)))
  print("  Should complete: " .. tostring(require("neoai.completion").should_complete()))
end

-- Prefetch completions for current file
local function prefetch_completions()
  if require("neoai.completion").should_prefetch() then
    require("neoai.completion").prefetch()
    print("Prefetching completions...")
  else
    print("Prefetch not available")
  end
end

-- Set up completion keymaps
vim.keymap.set("i", "<C-;>", trigger_completion,
  { desc = "NeoAI: Trigger Completion" })

vim.keymap.set("i", "<C-Enter>", accept_completion,
  { desc = "NeoAI: Accept Completion" })

vim.keymap.set("i", "<C-Esc>", clear_completion,
  { desc = "NeoAI: Clear Completion" })

vim.keymap.set("n", "<leader>tc", toggle_completion,
  { desc = "NeoAI: Toggle Completion" })

vim.keymap.set("n", "<leader>cs", check_completion_status,
  { desc = "NeoAI: Completion Status" })

vim.keymap.set("n", "<leader>cp", prefetch_completions,
  { desc = "NeoAI: Prefetch Completions" })

-- Example: Custom completion trigger for specific filetypes
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "python", "javascript", "typescript", "lua" },
  callback = function()
    -- Enable faster completion for programming languages
    local config = require("neoai.config")
    config.set("completion.debounce_ms", 150)
    config.set("completion.trigger_length", 2)
  end,
})

-- Example: Disable completion in specific contexts
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*.md",
  callback = function()
    -- Disable auto-completion for markdown files
    local state = require("neoai.state")
    state.active = false
  end,
})

-- Example: Show completion statistics
local function show_completion_stats()
  local state = require("neoai.state")
  
  print("Completion Statistics:")
  print("  Requests sent: " .. (state.requests_counter or 0))
  print("  Cache hits: " .. (state.cache_hits or 0))
  print("  Rendered completion: " .. (state.rendered_completion and "yes" or "no"))
end

vim.keymap.set("n", "<leader>cstats", show_completion_stats,
  { desc = "NeoAI: Completion Statistics" })

-- Example: Custom completion for specific patterns
vim.api.nvim_create_autocmd("InsertCharPre", {
  callback = function()
    local char = vim.v.char
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    
    -- Auto-trigger completion after certain patterns
    if char == "." or char == "(" or char == " " then
      vim.defer_fn(function()
        if require("neoai.completion").should_complete() then
          require("neoai.completion").trigger()
        end
      end, 50)
    end
  end,
})
