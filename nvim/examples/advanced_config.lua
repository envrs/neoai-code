-- Advanced NeoAI Configuration Example
-- This shows comprehensive configuration options

require("neoai").setup({
  -- API Configuration
  api_key = os.getenv("NEOAI_API_KEY"), -- Get from environment
  model = "gpt-4",
  
  -- Feature toggles
  features = {
    chat_interface = true,
    auto_complete = true,
    workspace_integration = true,
    lsp_integration = true,
  },
  
  -- Completion settings
  completion = {
    trigger_length = 3,           -- Minimum characters to trigger
    max_suggestions = 5,           -- Max suggestions to show
    debounce_ms = 300,             -- Debounce time in ms
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
    max_messages = 50,             -- Chat history limit
    context_lines = 20,            -- Context lines to include
  },
  
  -- Custom keymaps
  keymaps = {
    enabled = true,                -- Enable default keymaps
    override_conflicts = false,    -- Don't override existing keymaps
    show_conflict_warnings = true,  -- Show conflict warnings
    custom_keymaps = {
      {
        mode = "n",
        lhs = "<leader>ai",
        rhs = function()
          require("neoai.chat").toggle()
        end,
        opts = { desc = "NeoAI Chat", silent = true },
      },
      {
        mode = "i",
        lhs = "<C-;>",
        rhs = function()
          require("neoai.completion").trigger()
        end,
        opts = { desc = "NeoAI Complete", silent = true },
      },
    },
  },
  
  -- Workspace configuration
  workspace_folders = {
    paths = { "~/projects", "~/work" },
    lsp = true,                    -- Use LSP for workspace detection
    get_paths = function()
      -- Custom function to get workspace paths
      return vim.fn.glob("~/dev/*", false, true)
    end,
  },
  
  -- Enterprise settings (if using NeoAI Enterprise)
  neoai_enterprise_host = "https://your-company.neoai.com",
  ignore_certificate_errors = false,
  
  -- Logging
  log_file_path = vim.fn.stdpath("cache") .. "/neoai.log",
  debug = false,                   -- Enable debug mode
})
