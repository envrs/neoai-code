local M = {}

-- Plugin name
M.NAME = "neoai"

-- Default configuration
M.DEFAULT_CONFIG = {
    -- API settings
    api_key = nil,
    api_endpoint = "https://api.openai.com/v1",
    model = "gpt-4",
    
    -- Chat settings
    chat_window = {
        width = 80,
        height = 20,
        border = "single",
    },
    
    -- Keymaps configuration
    keymaps = {
        enabled = true,
        override_conflicts = false,
        show_conflict_warnings = true,
        custom_keymaps = {},
    },
    
    -- Plugin behavior
    auto_start = true,
    auto_save_config = true,
    debug_mode = false,
    
    -- Performance settings
    performance = {
        max_concurrent_requests = 3,
        request_timeout = 30000,
        cache_enabled = true,
        cache_ttl = 3600,
    },
    
    -- Completion settings
    completion = {
        enabled = true,
        max_tokens = 100,
        temperature = 0.7,
        debounce_ms = 300,
        exclude_filetypes = {
            "gitcommit",
            "gitrebase",
            "svn",
            "hgcommit",
            "cvsrc",
            "cvs",
            ".cvsrc",
            "svncommit",
            "hg",
            "diff",
            "patch",
            "orig",
            "rej",
            "commit",
            "tag",
            "git",
            "gitconfig",
            "help",
            "man",
            "qf",
            "loc",
            "startify",
            "vim-plug",
            "fugitive",
            "fugitiveblame",
            "nerdtree",
            "NvimTree",
            "neo-tree",
            "Outline",
            "alpha",
            "dashboard",
            "TelescopePrompt",
            "TelescopeResults",
            "WhichKey",
            "lspinfo",
            "null-ls-info",
            "checkhealth",
            "health",
            "log",
            "markdown",
            "text",
            "rst",
        },
    },
    
    -- Feature flags
    features = {
        auto_complete = true,
        chat_interface = true,
        workspace_integration = true,
        lsp_integration = true,
    },
}

-- Command names
M.COMMANDS = {
    CHAT = "NeoaiChat",
    COMPLETE = "NeoaiComplete",
    TOGGLE = "NeoaiToggle",
    CONFIG = "NeoaiConfig",
    STATUS = "NeoaiStatus",
}

-- Autocommand groups
M.AUGROUPS = {
    NEOAI = "Neoai",
    COMPLETION = "NeoaiCompletion",
    CHAT = "NeoaiChat",
}

-- File patterns
M.FILE_PATTERNS = {
    CODE = { "*.lua", "*.py", "*.js", "*.ts", "*.java", "*.cpp", "*.c", "*.go", "*.rs" },
    CONFIG = { "*.json", "*.yaml", "*.yml", "*.toml", "*.ini" },
    DOCUMENTATION = { "*.md", "*.txt", "*.rst" },
}

-- Status indicators
M.STATUS = {
    LOADING = "⟳",
    ERROR = "✗",
    SUCCESS = "✓",
    READY = "●",
}

return M