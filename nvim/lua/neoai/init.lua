local config = require("neoai.config")
local state = require("neoai.state")
local workspace = require("neoai.workspace")
local status = require("neoai.status")

local M = {}

-- Plugin setup
function M.setup(user_config)
    -- Initialize state
    state.init()
    
    -- Initialize workspace
    workspace.init()
    
    -- Setup configuration
    config.setup(user_config)
    
    -- Register status updates
    status.register_updates()
    
    vim.notify("NeoAI: Plugin loaded successfully", vim.log.levels.INFO)
end

-- Get plugin status
function M.status()
    return status.get_detailed_status()
end

-- Get workspace context
function M.get_context(opts)
    return workspace.get_context(opts.max_files, opts.max_content)
end

-- Check if plugin is ready
function M.is_ready()
    return status.is_ready()
end

-- Check if plugin is healthy
function M.is_healthy()
    return status.is_healthy()
end

-- Get configuration
function M.get_config()
    return config.get()
end

-- Update configuration
function M.update_config(new_config)
    config.setup(new_config)
end

-- Get workspace statistics
function M.get_workspace_stats()
    return workspace.get_statistics()
end

-- Find files in workspace
function M.find_files(pattern, file_type)
    return workspace.find_files(pattern, file_type)
end

-- Get file from workspace
function M.get_file(path)
    return workspace.get_file(path)
end

-- Reload plugin
function M.reload()
    -- Clear state
    state.reset()
    
    -- Reinitialize
    state.init()
    workspace.init()
    
    vim.notify("NeoAI: Plugin reloaded", vim.log.levels.INFO)
end

-- Plugin metadata
M.version = "1.0.0"
M.name = "neoai"

return M
