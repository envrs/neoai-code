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
    
    -- Completion settings
    completion = {
        enabled = true,
        max_tokens = 100,
        temperature = 0.7,
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