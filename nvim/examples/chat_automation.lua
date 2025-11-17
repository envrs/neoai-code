-- Chat Interface Automation Examples
-- This demonstrates advanced chat automation and integration

require("neoai").setup({
  api_key = "your-api-key-here",
  features = {
    chat_interface = true,
  },
  chat = {
    max_messages = 100,            -- Larger chat history
    context_lines = 50,            -- More context for complex tasks
  },
})

-- Auto-send current buffer content to chat
local function send_buffer_to_chat()
  local chat = require("neoai.chat")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local content = table.concat(lines, "\n")
  local filename = vim.fn.expand("%:t")
  
  local message = string.format("Here's the content of %s:\n\n```%s\n%s\n```", 
    filename, vim.bo.filetype, content)
  
  chat.submit_message(message)
  chat.open()  -- Open chat if not already open
end

-- Send selected text to chat
local function send_selection_to_chat()
  local chat = require("neoai.chat")
  local mode = vim.fn.mode()
  
  if mode == "v" or mode == "V" or mode == "^V" then
    -- Get selected text
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)
    
    -- Adjust first and last lines for selection
    if #lines > 0 then
      lines[1] = string.sub(lines[1], start_pos[3])
      lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
    end
    
    local content = table.concat(lines, "\n")
    local filename = vim.fn.expand("%:t")
    
    local message = string.format("Selected text from %s:\n\n```%s\n%s\n```", 
      filename, vim.bo.filetype, content)
    
    chat.submit_message(message)
    chat.open()
  else
    print("No text selected")
  end
end

-- Ask about current function/symbol
local function ask_about_current_function()
  local chat = require("neoai.chat")
  local lsp = require("neoai.lsp")
  local bufnr = vim.api.nvim_get_current_buf()
  local line = vim.fn.line(".") - 1
  local col = vim.fn.col(".") - 1
  
  -- Get current symbol using LSP
  lsp.get_document_symbols(bufnr, function(symbols)
    local current_symbol = nil
    
    for _, symbol in ipairs(symbols) do
      local range = symbol.location.range
      if line >= range.start.line and line <= range["end"].line then
        current_symbol = symbol
        break
      end
    end
    
    local message
    if current_symbol then
      -- Get symbol content
      local start_line = current_symbol.location.range.start.line
      local end_line = current_symbol.location.range["end"].line
      local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line + 1, false)
      local content = table.concat(lines, "\n")
      
      message = string.format("Can you explain this %s function `%s`?\n\n```%s\n%s\n```", 
        vim.bo.filetype, current_symbol.name, vim.bo.filetype, content)
    else
      -- Fallback to current line
      local current_line = vim.api.nvim_get_current_line()
      message = string.format("Can you explain this line of code?\n\n```%s\n%s\n```", 
        vim.bo.filetype, current_line)
    end
    
    chat.submit_message(message)
    chat.open()
  end)
end

-- Generate documentation for current function
local function generate_documentation()
  local chat = require("neoai.chat")
  local lsp = require("neoai.lsp")
  local bufnr = vim.api.nvim_get_current_buf()
  local line = vim.fn.line(".") - 1
  
  lsp.get_document_symbols(bufnr, function(symbols)
    local current_symbol = nil
    
    for _, symbol in ipairs(symbols) do
      local range = symbol.location.range
      if line >= range.start.line and line <= range["end"].line then
        current_symbol = symbol
        break
      end
    end
    
    if current_symbol then
      local start_line = current_symbol.location.range.start.line
      local end_line = current_symbol.location.range["end"].line
      local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line + 1, false)
      local content = table.concat(lines, "\n")
      
      local message = string.format("Generate comprehensive documentation for this %s function `%s` including:\n- Description of what it does\n- Parameters and their types\n- Return value\n- Usage examples\n\n```%s\n%s\n```", 
        vim.bo.filetype, current_symbol.name, vim.bo.filetype, content)
      
      chat.submit_message(message)
      chat.open()
    else
      print("No function found at cursor")
    end
  end)
end

-- Refactor current code
local function refactor_code()
  local chat = require("neoai.chat")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local content = table.concat(lines, "\n")
  local filename = vim.fn.expand("%:t")
  
  local message = string.format("Please refactor this %s code to improve:\n- Readability\n- Performance\n- Code organization\n- Best practices\n\nOriginal code:\n\n```%s\n%s\n```\n\nProvide the refactored version with explanations for the changes made.", 
    vim.bo.filetype, vim.bo.filetype, content)
  
  chat.submit_message(message)
  chat.open()
end

-- Debug current code
local function debug_code()
  local chat = require("neoai.chat")
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local content = table.concat(lines, "\n")
  local filename = vim.fn.expand("%:t")
  
  local message = string.format("Help me debug this %s code. Identify potential issues, bugs, or improvements:\n\n```%s\n%s\n```", 
    vim.bo.filetype, vim.bo.filetype, content)
  
  chat.submit_message(message)
  chat.open()
end

-- Set up automation keymaps
vim.keymap.set("n", "<leader>cab", send_buffer_to_chat,
  { desc = "NeoAI: Send Buffer to Chat" })

vim.keymap.set("v", "<leader>cas", send_selection_to_chat,
  { desc = "NeoAI: Send Selection to Chat" })

vim.keymap.set("n", "<leader>caf", ask_about_current_function,
  { desc = "NeoAI: Ask About Function" })

vim.keymap.set("n", "<leader>cad", generate_documentation,
  { desc = "NeoAI: Generate Documentation" })

vim.keymap.set("n", "<leader>car", refactor_code,
  { desc = "NeoAI: Refactor Code" })

vim.keymap.set("n", "<leader>cade", debug_code,
  { desc = "NeoAI: Debug Code" })

-- Auto-open chat for certain file types
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = { "*.py", "*.js", "*.ts", "*.lua" },
  callback = function()
    -- Auto-open chat when entering certain file types
    -- Uncomment the next line if you want this behavior
    -- require("neoai.chat").open()
  end,
})

-- Custom chat commands
local function create_custom_chat_commands()
  local chat = require("neoai.chat")
  
  -- Create a new conversation with a specific context
  vim.api.nvim_create_user_command("NeoaiChatContext", function(opts)
    local context = opts.args
    chat.new_conversation()
    chat.submit_message("I'm working on: " .. context)
    chat.open()
  end, { nargs = 1 })
  
  -- Quick code review command
  vim.api.nvim_create_user_command("NeoaiReview", function()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local content = table.concat(lines, "\n")
    local filename = vim.fn.expand("%:t")
    
    local message = string.format("Please review this %s code for:\n- Code quality\n- Best practices\n- Security issues\n- Performance\n- Style improvements\n\n```%s\n%s\n```", 
      vim.bo.filetype, vim.bo.filetype, content)
    
    chat.new_conversation()
    chat.submit_message(message)
    chat.open()
  end, {})
end

create_custom_chat_commands()
