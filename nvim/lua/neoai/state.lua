local M = {}

-- Plugin state
local state = {
    -- Connection state
    connected = false,
    api_key_valid = false,
    
    -- Chat state
    chat_active = false,
    chat_buffer = nil,
    chat_window = nil,
    
    -- Completion state
    completion_active = false,
    completion_context = nil,
    
    -- Workspace state
    workspace_root = nil,
    workspace_files = {},
    
    -- Error state
    last_error = nil,
    error_count = 0,
    
    -- Performance metrics
    request_count = 0,
    total_response_time = 0,
    last_request_time = nil,
}

-- Initialize state
function M.init()
    state.workspace_root = vim.fn.getcwd()
    state.connected = false
    state.chat_active = false
    state.completion_active = false
    state.last_error = nil
    state.error_count = 0
    state.request_count = 0
    state.total_response_time = 0
    state.last_request_time = nil
end

-- Get state value
function M.get(key)
    if key then
        return state[key]
    end
    return vim.deepcopy(state)
end

-- Set state value
function M.set(key, value)
    state[key] = value
end

-- Update connection state
function M.set_connected(connected, api_key_valid)
    state.connected = connected
    if api_key_valid ~= nil then
        state.api_key_valid = api_key_valid
    end
end

-- Update chat state
function M.set_chat_active(active, buffer, window)
    state.chat_active = active
    state.chat_buffer = buffer
    state.chat_window = window
end

-- Update completion state
function M.set_completion_active(active, context)
    state.completion_active = active
    state.completion_context = context
end

-- Set workspace root
function M.set_workspace_root(root)
    state.workspace_root = root
end

-- Update workspace files
function M.update_workspace_files(files)
    state.workspace_files = files
end

-- Record error
function M.record_error(error)
    state.last_error = error
    state.error_count = state.error_count + 1
    vim.schedule(function()
        vim.notify("NeoAI Error: " .. tostring(error), vim.log.levels.ERROR)
    end)
end

-- Clear error
function M.clear_error()
    state.last_error = nil
end

-- Record request metrics
function M.record_request(response_time)
    state.request_count = state.request_count + 1
    state.total_response_time = state.total_response_time + response_time
    state.last_request_time = os.time()
end

-- Get average response time
function M.get_average_response_time()
    if state.request_count == 0 then
        return 0
    end
    return state.total_response_time / state.request_count
end

-- Check if healthy
function M.is_healthy()
    return state.connected and state.api_key_valid and state.last_error == nil
end

-- Reset state
function M.reset()
    M.init()
end

return M