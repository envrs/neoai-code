-- Enterprise Setup Example
-- This demonstrates NeoAI Enterprise configuration

require("neoai").setup({
  -- Enterprise configuration
  neoai_enterprise_host = "https://your-company.neoai.com",
  api_key = os.getenv("NEOAI_ENTERPRISE_API_KEY"),
  
  -- Enterprise-specific settings
  ignore_certificate_errors = false,  -- Set to true if using custom certificates
  
  -- Model configuration (Enterprise might have different models)
  model = "gpt-4-enterprise",
  
  -- Enhanced security - don't log sensitive content
  log_file_path = nil,  -- Disable file logging for security
  
  -- Workspace configuration for enterprise environments
  workspace_folders = {
    paths = {
      "/projects/company-project",
      "/work/enterprise-app",
      "~/company-code",
    },
    lsp = true,
    get_paths = function()
      -- Get paths from company-specific environment variables
      local company_paths = os.getenv("COMPANY_PROJECT_PATHS")
      if company_paths then
        return vim.split(company_paths, ":", { trimempty = true })
      end
      return {}
    end,
  },
  
  -- Enterprise keymap configuration
  keymaps = {
    enabled = true,
    override_conflicts = false,
    show_conflict_warnings = true,
    custom_keymaps = {
      {
        mode = "n",
        lhs = "<leader>ei",
        rhs = function()
          require("neoai.chat").toggle()
        end,
        opts = { desc = "Enterprise AI: Toggle Chat", silent = true },
      },
      {
        mode = "n",
        lhs = "<leader>es",
        rhs = function()
          require("neoai").status()
        end,
        opts = { desc = "Enterprise AI: Status", silent = true },
      },
    },
  },
  
  -- Enterprise completion settings
  completion = {
    trigger_length = 3,
    max_suggestions = 3,  -- More conservative for enterprise
    debounce_ms = 500,     -- Slightly slower to reduce server load
    exclude_filetypes = {
      "gitcommit", "gitrebase", "svn", "hgcommit",
      "help", "man", "qf", "startify", "nerdtree", 
      "NvimTree", "neo-tree", "alpha", "dashboard",
      "TelescopePrompt", "WhichKey", "lspinfo",
      "checkhealth", "log", "markdown", "text", "rst",
      -- Additional enterprise exclusions
      "confidential", "secrets", "config",
    },
  },
  
  -- Enterprise chat settings
  chat = {
    max_messages = 25,     -- Smaller history for privacy
    context_lines = 10,    -- Less context to reduce data transfer
  },
})

-- Enterprise-specific utilities
local enterprise_utils = {}

-- Check if connected to enterprise instance
function enterprise_utils.is_enterprise_connected()
  local config = require("neoai.config")
  return config.is_enterprise()
end

-- Get enterprise status
function enterprise_utils.get_enterprise_status()
  local config = require("neoai.config")
  local host = config.get("neoai_enterprise_host")
  
  if host then
    return {
      connected = true,
      host = host,
      model = config.get("model"),
      api_key_set = os.getenv("NEOAI_ENTERPRISE_API_KEY") ~= nil,
    }
  else
    return {
      connected = false,
      host = nil,
      model = config.get("model"),
      api_key_set = false,
    }
  end
end

-- Enterprise workspace management
function enterprise_utils.setup_enterprise_workspaces()
  local workspace = require("neoai.workspace")
  
  -- Auto-detect enterprise project structure
  local function detect_enterprise_projects()
    local projects = {}
    
    -- Check for common enterprise project markers
    local markers = {
      ".enterprise-project",
      "company-project.json",
      "workspace.config",
    }
    
    for _, marker in ipairs(markers) do
      local files = vim.fn.findfile(marker, vim.fn.getcwd() .. "/**")
      if files and files ~= "" then
        local project_dir = vim.fn.fnamemodify(files, ":h")
        table.insert(projects, project_dir)
      end
    end
    
    return projects
  end
  
  local detected_projects = detect_enterprise_projects()
  if #detected_projects > 0 then
    workspace.init()
    print("Detected enterprise projects: " .. table.concat(detected_projects, ", "))
  end
end

-- Enterprise security utilities
function enterprise_utils.check_sensitive_content()
  local sensitive_patterns = {
    "password",
    "secret",
    "token",
    "api_key",
    "private_key",
    "credential",
  }
  
  local current_line = vim.api.nvim_get_current_line()
  for _, pattern in ipairs(sensitive_patterns) do
    if current_line:lower():find(pattern) then
      return true
    end
  end
  return false
end

-- Set up enterprise-specific keymaps
vim.keymap.set("n", "<leader>einfo", function()
  local status = enterprise_utils.get_enterprise_status()
  print("Enterprise AI Status:")
  print("  Connected: " .. tostring(status.connected))
  print("  Host: " .. (status.host or "N/A"))
  print("  Model: " .. status.model)
  print("  API Key: " .. (status.api_key_set and "Set" or "Not set"))
end, { desc = "Enterprise AI: Show Status" })

vim.keymap.set("n", "<leader>ework", enterprise_utils.setup_enterprise_workspaces,
  { desc = "Enterprise AI: Setup Workspaces" })

vim.keymap.set("n", "<leader>esec", function()
  if enterprise_utils.check_sensitive_content() then
    print("⚠️  Sensitive content detected on current line")
  else
    print("✅ No sensitive content detected")
  end
end, { desc = "Enterprise AI: Check Sensitive Content" })

-- Enterprise-specific auto-commands
vim.api.nvim_create_autocmd("InsertEnter", {
  callback = function()
    -- Check for sensitive content before allowing completion
    if enterprise_utils.check_sensitive_content() then
      local state = require("neoai.state")
      state.active = false
      print("AI completion disabled for sensitive content")
    end
  end,
})

-- Enterprise health check
vim.api.nvim_create_user_command("NeoaiEnterpriseHealth", function()
  local health = require("neoai.health")
  local status = enterprise_utils.get_enterprise_status()
  
  print("Enterprise AI Health Check:")
  print("✅ Enterprise connection: " .. tostring(status.connected))
  print("✅ API key configured: " .. tostring(status.api_key_set))
  print("✅ Workspace initialized: " .. tostring(require("neoai.workspace").get_statistics().total_files > 0))
  
  if not status.connected then
    print("❌ Not connected to enterprise instance")
  end
  
  if not status.api_key_set then
    print("❌ Enterprise API key not configured")
    print("   Set NEOAI_ENTERPRISE_API_KEY environment variable")
  end
end, {})
