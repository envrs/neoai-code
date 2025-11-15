-- LSP Integration Example
-- This demonstrates how to use NeoAI's LSP features

require("neoai").setup({
  api_key = "your-api-key-here",
  features = {
    lsp_integration = true,
  },
})

-- Get LSP context for current buffer
local function show_lsp_context()
  local lsp = require("neoai.lsp")
  local bufnr = vim.api.nvim_get_current_buf()
  
  lsp.get_lsp_context(bufnr, 50, function(context)
    print("LSP Context:")
    print("  Language: " .. (context.language or "Unknown"))
    print("  Symbols: " .. #context.symbols)
    
    for _, symbol in ipairs(context.symbols) do
      print("    - " .. symbol.name .. " (" .. symbol.kind .. ")")
    end
  end)
end

-- Get document symbols
local function show_document_symbols()
  local lsp = require("neoai.lsp")
  local bufnr = vim.api.nvim_get_current_buf()
  
  lsp.get_document_symbols(bufnr, function(symbols)
    print("Document Symbols:")
    for _, symbol in ipairs(symbols) do
      local location = symbol.location
      local line = location.range.start.line + 1
      local col = location.range.start.character + 1
      print("  " .. symbol.name .. " (" .. symbol.kind .. ") at line " .. line .. ":" .. col)
    end
  end)
end

-- Get workspace symbols
local function show_workspace_symbols(query)
  local lsp = require("neoai.lsp")
  
  lsp.get_workspace_symbols(query or "", function(symbols)
    print("Workspace Symbols matching '" .. (query or "") .. "':")
    for _, symbol in ipairs(symbols) do
      local location = symbol.location
      local file = vim.uri_to_fname(location.uri)
      local line = location.range.start.line + 1
      print("  " .. symbol.name .. " (" .. symbol.kind .. ") in " .. file .. ":" .. line)
    end
  end)
end

-- Get code actions
local function show_code_actions()
  local lsp = require("neoai.lsp")
  local bufnr = vim.api.nvim_get_current_buf()
  local range = {
    start = { line = vim.fn.line(".") - 1, character = vim.fn.col(".") - 1 },
    ["end"] = { line = vim.fn.line(".") - 1, character = vim.fn.col(".") - 1 },
  }
  
  lsp.get_code_actions(bufnr, range, function(actions)
    print("Code Actions:")
    for _, action in ipairs(actions) do
      print("  - " .. action.title)
    end
  end)
end

-- Get hover information
local function show_hover_info()
  local lsp = require("neoai.lsp")
  local bufnr = vim.api.nvim_get_current_buf()
  local position = {
    line = vim.fn.line(".") - 1,
    character = vim.fn.col(".") - 1,
  }
  
  lsp.get_hover_info(bufnr, position, function(hover)
    if hover and hover.contents then
      print("Hover Info:")
      for _, content in ipairs(hover.contents) do
        if content.value then
          print("  " .. content.value)
        end
      end
    else
      print("No hover information available")
    end
  end)
end

-- Navigate to symbol
local function navigate_to_symbol()
  local lsp = require("neoai.lsp")
  local bufnr = vim.api.nvim_get_current_buf()
  local position = {
    line = vim.fn.line(".") - 1,
    character = vim.fn.col(".") - 1,
  }
  
  lsp.goto_definition(bufnr, position, function(location)
    if location then
      local file = vim.uri_to_fname(location.uri)
      local line = location.range.start.line + 1
      local col = location.range.start.character + 1
      
      vim.cmd("edit " .. file)
      vim.api.nvim_win_set_cursor(0, { line, col })
    else
      print("No definition found")
    end
  end)
end

-- Set up keymaps for LSP integration
vim.keymap.set("n", "<leader>lsc", show_lsp_context,
  { desc = "NeoAI: Show LSP Context" })

vim.keymap.set("n", "<leader>lss", show_document_symbols,
  { desc = "NeoAI: Show Document Symbols" })

vim.keymap.set("n", "<leader>lsw", function()
  vim.ui.input({ prompt = "Symbol query: " }, function(query)
    if query then
      show_workspace_symbols(query)
    end
  end)
end, { desc = "NeoAI: Search Workspace Symbols" })

vim.keymap.set("n", "<leader>lca", show_code_actions,
  { desc = "NeoAI: Show Code Actions" })

vim.keymap.set("n", "<leader>lh", show_hover_info,
  { desc = "NeoAI: Show Hover Info" })

vim.keymap.set("n", "<leader>lg", navigate_to_symbol,
  { desc = "NeoAI: Go to Definition" })

-- Auto-show symbols when entering a buffer
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    -- Only show symbols for programming files
    local ft = vim.bo.filetype
    if vim.tbl_contains({ "python", "javascript", "typescript", "lua", "java", "cpp", "c" }, ft) then
      show_document_symbols()
    end
  end,
})
