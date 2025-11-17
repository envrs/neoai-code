-- Language-Specific Examples
-- This demonstrates NeoAI configuration for different programming languages

require("neoai").setup({
  api_key = "your-api-key-here",
  features = {
    chat_interface = true,
    auto_complete = true,
    lsp_integration = true,
  },
})

-- Language-specific configurations
local language_configs = {
  python = {
    completion = {
      trigger_length = 2,
      debounce_ms = 150,
      exclude_filetypes = { "gitcommit", "python" },  -- Disable for some contexts
    },
    chat = {
      context_lines = 30,  -- Python needs more context for imports
    },
    custom_prompts = {
      explain = "Explain this Python code including its purpose, complexity, and any potential improvements.",
      debug = "Help me debug this Python code. Identify common Python pitfalls, syntax errors, and logical issues.",
      refactor = "Refactor this Python code following PEP 8 guidelines and Python best practices.",
    },
  },
  
  javascript = {
    completion = {
      trigger_length = 2,
      debounce_ms = 200,
    },
    chat = {
      context_lines = 25,
    },
    custom_prompts = {
      explain = "Explain this JavaScript code including ES6+ features, async patterns, and browser/Node.js context.",
      debug = "Debug this JavaScript code. Look for common issues like undefined variables, async problems, and type errors.",
      refactor = "Refactor this JavaScript code using modern ES6+ features and best practices.",
    },
  },
  
  typescript = {
    completion = {
      trigger_length = 2,
      debounce_ms = 200,
    },
    chat = {
      context_lines = 35,  -- TypeScript needs more context for types
    },
    custom_prompts = {
      explain = "Explain this TypeScript code including type definitions, generics, and interfaces.",
      debug = "Debug this TypeScript code. Focus on type errors, interface mismatches, and generic usage.",
      refactor = "Refactor this TypeScript code improving type safety and leveraging TypeScript features.",
    },
  },
  
  lua = {
    completion = {
      trigger_length = 2,
      debounce_ms = 100,  -- Faster for Lua
    },
    chat = {
      context_lines = 20,
    },
    custom_prompts = {
      explain = "Explain this Lua code including tables, metatables, and Lua-specific patterns.",
      debug = "Debug this Lua code. Look for table indexing issues, nil values, and scope problems.",
      refactor = "Refactor this Lua code following best practices for Neovim plugin development.",
    },
  },
  
  rust = {
    completion = {
      trigger_length = 3,
      debounce_ms = 300,  -- Rust is more complex
    },
    chat = {
      context_lines = 40,  -- Rust needs lots of context
    },
    custom_prompts = {
      explain = "Explain this Rust code including ownership, borrowing, lifetimes, and memory safety concepts.",
      debug = "Debug this Rust code. Focus on borrow checker errors, lifetime issues, and type mismatches.",
      refactor = "Refactor this Rust code improving performance, safety, and idiomatic Rust patterns.",
    },
  },
  
  go = {
    completion = {
      trigger_length = 2,
      debounce_ms = 200,
    },
    chat = {
      context_lines = 25,
    },
    custom_prompts = {
      explain = "Explain this Go code including goroutines, channels, and Go-specific idioms.",
      debug = "Debug this Go code. Look for race conditions, error handling issues, and interface problems.",
      refactor = "Refactor this Go code following Go conventions and improving concurrency patterns.",
    },
  },
}

-- Apply language-specific configuration
local function apply_language_config()
  local filetype = vim.bo.filetype
  local config = language_configs[filetype]
  
  if config then
    -- Update completion settings
    if config.completion then
      local neoai_config = require("neoai.config")
      for key, value in pairs(config.completion) do
        neoai_config.set("completion." .. key, value)
      end
    end
    
    -- Update chat settings
    if config.chat then
      local neoai_config = require("neoai.config")
      for key, value in pairs(config.chat) do
        neoai_config.set("chat." .. key, value)
      end
    end
    
    print("Applied " .. filetype .. " specific configuration")
  end
end

-- Language-specific helper functions
local function create_language_helpers()
  local chat = require("neoai.chat")
  
  -- Create language-specific commands
  vim.api.nvim_create_user_command("NeoaiExplain", function(opts)
    local filetype = vim.bo.filetype
    local config = language_configs[filetype]
    local prompt = config and config.custom_prompts and config.custom_prompts.explain or "Explain this code."
    
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local content = table.concat(lines, "\n")
    
    local message = string.format("%s\n\n```%s\n%s\n```", prompt, filetype, content)
    chat.submit_message(message)
    chat.open()
  end, { desc = "Explain current code" })
  
  vim.api.nvim_create_user_command("NeoaiDebug", function(opts)
    local filetype = vim.bo.filetype
    local config = language_configs[filetype]
    local prompt = config and config.custom_prompts and config.custom_prompts.debug or "Debug this code."
    
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local content = table.concat(lines, "\n")
    
    local message = string.format("%s\n\n```%s\n%s\n```", prompt, filetype, content)
    chat.submit_message(message)
    chat.open()
  end, { desc = "Debug current code" })
  
  vim.api.nvim_create_user_command("NeoaiRefactor", function(opts)
    local filetype = vim.bo.filetype
    local config = language_configs[filetype]
    local prompt = config and config.custom_prompts and config.custom_prompts.refactor or "Refactor this code."
    
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local content = table.concat(lines, "\n")
    
    local message = string.format("%s\n\n```%s\n%s\n```", prompt, filetype, content)
    chat.submit_message(message)
    chat.open()
  end, { desc = "Refactor current code" })
end

-- Language-specific keymaps
local function setup_language_keymaps()
  local filetype = vim.bo.filetype
  
  -- Python-specific keymaps
  if filetype == "python" then
    vim.keymap.set("n", "<leader>pydoc", function()
      local chat = require("neoai.chat")
      local line = vim.fn.getline(".")
      
      -- Try to extract function/class name
      local name = line:match("def%s+(%w+)") or line:match("class%s+(%w+)")
      
      if name then
        local message = string.format("Generate Python docstring for function `%s` following Google style conventions.", name)
        chat.submit_message(message)
        chat.open()
      else
        print("No function or class found on current line")
      end
    end, { desc = "Python: Generate Docstring" })
    
    vim.keymap.set("n", "<leader>pytest", function()
      local chat = require("neoai.chat")
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local content = table.concat(lines, "\n")
      
      local message = string.format("Generate comprehensive unit tests for this Python code using pytest:\n\n```python\n%s\n```", content)
      chat.submit_message(message)
      chat.open()
    end, { desc = "Python: Generate Tests" })
  end
  
  -- JavaScript/TypeScript-specific keymaps
  if filetype == "javascript" or filetype == "typescript" then
    vim.keymap.set("n", "<leader>jsdoc", function()
      local chat = require("neoai.chat")
      local line = vim.fn.getline(".")
      
      local name = line:match("function%s+(%w+)") or line:match("const%s+(%w+)%s*=") or line:match("class%s+(%w+)")
      
      if name then
        local message = string.format("Generate JSDoc comments for function `%s`.", name)
        chat.submit_message(message)
        chat.open()
      else
        print("No function found on current line")
      end
    end, { desc = "JS/TS: Generate JSDoc" })
    
    vim.keymap.set("n", "<leader>jest", function()
      local chat = require("neoai.chat")
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local content = table.concat(lines, "\n")
      
      local message = string.format("Generate Jest tests for this %s code:\n\n```%s\n%s\n```", filetype, filetype, content)
      chat.submit_message(message)
      chat.open()
    end, { desc = "JS/TS: Generate Jest Tests" })
  end
  
  -- Rust-specific keymaps
  if filetype == "rust" then
    vim.keymap.set("n", "<leader>rustdoc", function()
      local chat = require("neoai.chat")
      local line = vim.fn.getline(".")
      
      local name = line:match("fn%s+(%w+)") or line:match("struct%s+(%w+)") or line:match("impl%s+(%w+)")
      
      if name then
        local message = string.format("Generate Rust documentation comments for `%s` including examples.", name)
        chat.submit_message(message)
        chat.open()
      else
        print("No function or struct found on current line")
      end
    end, { desc = "Rust: Generate Documentation" })
    
    vim.keymap.set("n", "<leader>rusttest", function()
      local chat = require("neoai.chat")
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local content = table.concat(lines, "\n")
      
      local message = string.format("Generate Rust unit tests and integration tests for this code:\n\n```rust\n%s\n```", content)
      chat.submit_message(message)
      chat.open()
    end, { desc = "Rust: Generate Tests" })
  end
  
  -- Lua-specific keymaps (for Neovim plugin development)
  if filetype == "lua" then
    vim.keymap.set("n", "<leader>luadoc", function()
      local chat = require("neoai.chat")
      local line = vim.fn.getline(".")
      
      local name = line:match("function%s+(%w+%.%w+)") or line:match("local%s+function%s+(%w+)")
      
      if name then
        local message = string.format("Generate Lua documentation for function `%s` including parameter types and return values.", name)
        chat.submit_message(message)
        chat.open()
      else
        print("No function found on current line")
      end
    end, { desc = "Lua: Generate Documentation" })
  end
end

-- Auto-apply language configuration when entering a buffer
vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    apply_language_config()
    setup_language_keymaps()
  end,
})

-- Initialize language helpers
create_language_helpers()

-- Quick language switching
vim.api.nvim_create_user_command("NeoaiLanguage", function(opts)
  local filetype = opts.args
  if language_configs[filetype] then
    vim.bo.filetype = filetype
    apply_language_config()
    setup_language_keymaps()
    print("Switched to " .. filetype .. " configuration")
  else
    print("No configuration available for: " .. filetype)
    print("Available languages: " .. table.concat(vim.tbl_keys(language_configs), ", "))
  end
end, { 
  nargs = 1,
  complete = function()
    return vim.tbl_keys(language_configs)
  end,
  desc = "Switch NeoAI language configuration"
})
