local consts = require("neoai.consts")
local config = require("neoai.config")
local state = require("neoai.state")
local features = require("neoai.features")
local utils = require("neoai.utils")

local M = {}

-- Command implementations
local commands = {}

-- Chat command
commands[consts.COMMANDS.CHAT] = function(opts)
    if not features.is_enabled("chat_interface") then
        vim.notify("NeoAI: Chat interface is disabled", vim.log.levels.WARN)
        return
    end
    
    local chat = require("neoai.chat")
    chat.toggle()
end

-- Complete command
commands[consts.COMMANDS.COMPLETE] = function(opts)
    if not features.is_enabled("auto_complete") then
        vim.notify("NeoAI: Auto completion is disabled", vim.log.levels.WARN)
        return
    end
    
    local completion = require("neoai.completion")
    completion.trigger_completion()
end

-- Toggle command
commands[consts.COMMANDS.TOGGLE] = function(opts)
    local feature = opts.args
    if utils.is_empty(feature) then
        vim.notify("NeoAI: Usage: " .. consts.COMMANDS.TOGGLE .. " <feature>", vim.log.levels.ERROR)
        return
    end
    
    if features.is_enabled(feature) then
        features.disable(feature)
    else
        features.enable(feature)
    end
end

-- Config command
commands[consts.COMMANDS.CONFIG] = function(opts)
    local action = opts.args
    if action == "show" then
        local current_config = config.get()
        vim.notify("NeoAI Config:\n" .. vim.inspect(current_config), vim.log.levels.INFO)
    elseif action == "reset" then
        config.setup(consts.DEFAULT_CONFIG)
        vim.notify("NeoAI: Configuration reset to defaults", vim.log.levels.INFO)
    else
        vim.notify("NeoAI: Usage: " .. consts.COMMANDS.CONFIG .. " <show|reset>", vim.log.levels.ERROR)
    end
end

-- Status command
commands[consts.COMMANDS.STATUS] = function(opts)
    local current_state = state.get()
    local enabled_features = features.list_enabled()
    
    local status_info = string.format([[
NeoAI Status:
- Connected: %s
- API Key Valid: %s
- Chat Active: %s
- Completion Active: %s
- Workspace Root: %s
- Requests: %d
- Avg Response Time: %s
- Errors: %d
- Enabled Features: %s
]], 
        current_state.connected and "Yes" or "No",
        current_state.api_key_valid and "Yes" or "No",
        current_state.chat_active and "Yes" or "No",
        current_state.completion_active and "Yes" or "No",
        current_state.workspace_root or "Unknown",
        current_state.request_count,
        utils.format_time(state.get_average_response_time()),
        current_state.error_count,
        utils.join(enabled_features, ", ")
    )
    
    vim.notify(status_info, vim.log.levels.INFO)
end

-- Setup user commands
function M.setup()
    for command_name, command_func in pairs(commands) do
        vim.api.nvim_create_user_command(command_name, command_func, {
            nargs = "?",
            desc = "NeoAI command: " .. command_name,
        })
    end
    
    vim.notify("NeoAI: User commands registered", vim.log.levels.DEBUG)
end

-- Get all commands
function M.get_commands()
    return vim.tbl_keys(commands)
end

-- Execute command by name
function M.execute(command_name, opts)
    opts = opts or {}
    local command_func = commands[command_name]
    if command_func then
        command_func(opts)
    else
        vim.notify("NeoAI: Unknown command: " .. command_name, vim.log.levels.ERROR)
    end
end

return M