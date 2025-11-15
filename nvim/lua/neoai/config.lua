local consts = require("neoai.consts")

local M = {}

-- Global configuration
local config = vim.deepcopy(consts.DEFAULT_CONFIG)

-- Setup function
function M.setup(user_config)
    config = vim.tbl_deep_extend("force", config, user_config or {})
    
    -- Validate required settings
    if not config.api_key then
        vim.notify("NeoAI: API key not configured. Set config.api_key", vim.log.levels.WARN)
    end
    
    -- Initialize features
    local features = require("neoai.features")
    features.init(config.features)
    
    -- Setup autocommands
    local auto_commands = require("neoai.auto_commands")
    auto_commands.setup()
    
    -- Setup user commands
    local user_commands = require("neoai.user_commands")
    user_commands.setup()
    
    -- Setup keymaps
    local keymaps = require("neoai.keymaps")
    keymaps.setup()
    
    -- Initialize LSP if enabled
    if config.features.lsp_integration then
        local lsp = require("neoai.lsp")
        lsp.setup()
    end
    
    vim.notify("NeoAI: Plugin initialized", vim.log.levels.INFO)
end

-- Get configuration value
function M.get(key)
    if key then
        return config[key]
    end
    return config
end

-- Set configuration value
function M.set(key, value)
    config[key] = value
end

-- Check if feature is enabled
function M.is_feature_enabled(feature)
    return config.features[feature] == true
end

-- Get API configuration
function M.get_api_config()
    return {
        api_key = config.api_key,
        api_endpoint = config.api_endpoint,
        model = config.model,
    }
end

-- Get chat configuration
function M.get_chat_config()
    return config.chat_window
end

-- Get completion configuration
function M.get_completion_config()
    return config.completion
end

return M