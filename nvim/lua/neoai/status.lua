local consts = require("neoai.consts")
local state = require("neoai.state")
local features = require("neoai.features")
local utils = require("neoai.utils")

local M = {}

-- Get status indicator
function M.get_indicator()
    local current_state = state.get()
    
    if current_state.last_error then
        return consts.STATUS.ERROR
    elseif current_state.connected and current_state.api_key_valid then
        return consts.STATUS.SUCCESS
    elseif current_state.connected then
        return consts.STATUS.LOADING
    else
        return consts.STATUS.READY
    end
end

-- Get status message
function M.get_message()
    local current_state = state.get()
    
    if current_state.last_error then
        return "Error: " .. tostring(current_state.last_error)
    elseif current_state.connected and current_state.api_key_valid then
        return "Connected"
    elseif current_state.connected then
        return "Connecting..."
    else
        return "Disconnected"
    end
end

-- Get detailed status
function M.get_detailed_status()
    local current_state = state.get()
    local enabled_features = features.list_enabled()
    
    return {
        indicator = M.get_indicator(),
        message = M.get_message(),
        connected = current_state.connected,
        api_key_valid = current_state.api_key_valid,
        chat_active = current_state.chat_active,
        completion_active = current_state.completion_active,
        workspace_root = current_state.workspace_root,
        request_count = current_state.request_count,
        average_response_time = state.get_average_response_time(),
        error_count = current_state.error_count,
        last_error = current_state.last_error,
        enabled_features = enabled_features,
        healthy = state.is_healthy(),
    }
end

-- Format status for display
function M.format_status(format)
    format = format or "compact"
    local status = M.get_detailed_status()
    
    if format == "compact" then
        return status.indicator .. " " .. status.message
    elseif format == "detailed" then
        return string.format([[
%s %s
- Requests: %d | Avg Time: %s | Errors: %d
- Features: %s
]], 
            status.indicator,
            status.message,
            status.request_count,
            utils.format_time(status.average_response_time),
            status.error_count,
            utils.join(status.enabled_features, ", ")
        )
    elseif format == "json" then
        return vim.json.encode(status)
    else
        return M.get_message()
    end
end

-- Check if plugin is ready
function M.is_ready()
    local current_state = state.get()
    return current_state.connected and current_state.api_key_valid
end

-- Check if plugin is healthy
function M.is_healthy()
    return state.is_healthy()
end

-- Show status notification
function M.show_notification(level)
    level = level or vim.log.levels.INFO
    local message = M.format_status("detailed")
    vim.notify(message, level)
end

-- Update status display
function M.update_display()
    -- Update lualine if available
    pcall(function()
        local lualine = require("lualine")
        if lualine then
            vim.cmd("LualineRefresh")
        end
    end)
    
    -- Update statusline
    local status = M.format_status("compact")
    vim.opt.statusline = vim.opt.statusline:gsub("%%{neoai%.status%.get_indicator%%}", status)
end

-- Register status updates
function M.register_updates()
    -- Update status on state changes
    local state_update_group = vim.api.nvim_create_augroup("NeoaiStatusUpdate", { clear = true })
    
    vim.api.nvim_create_autocmd("User", {
        group = state_update_group,
        pattern = "NeoaiStateChanged",
        callback = function()
            M.update_display()
        end,
        desc = "NeoAI: Update status display on state change",
    })
end

return M