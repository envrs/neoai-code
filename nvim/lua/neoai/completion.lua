local consts = require("neoai.consts")
local config = require("neoai.config")
local state = require("neoai.state")
local features = require("neoai.features")
local utils = require("neoai.utils")

local M = {}

-- Completion state
local completion_state = {
    active = false,
    context = nil,
    request_id = nil,
    suggestions = {},
    current_suggestion = 0,
}

-- Initialize completion
function M.init()
    completion_state.active = false
    completion_state.context = nil
    completion_state.request_id = nil
    completion_state.suggestions = {}
    completion_state.current_suggestion = 0
end

-- Trigger completion manually
function M.trigger_completion()
    if not features.is_enabled("auto_complete") then
        return
    end
    
    local context = M.get_completion_context()
    if not context or #context.prefix < 3 then
        return
    end
    
    M.request_completion(context)
end

-- Auto-trigger completion
function M.auto_trigger()
    if not features.is_enabled("auto_complete") or completion_state.active then
        return
    end
    
    local context = M.get_completion_context()
    if not context or #context.prefix < 3 then
        return
    end
    
    -- Debounced auto-trigger
    local debounced_trigger = utils.debounce(function()
        M.request_completion(context)
    end, 500)
    
    debounced_trigger()
end

-- Get completion context
function M.get_completion_context()
    local bufnr = vim.api.nvim_get_current_buf()
    local cursor = utils.get_cursor()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    
    -- Get current line up to cursor
    local current_line = lines[cursor[1]] or ""
    local prefix = current_line:sub(1, cursor[2])
    
    -- Get surrounding context
    local start_line = math.max(1, cursor[1] - 10)
    local end_line = math.min(#lines, cursor[1] + 5)
    local context_lines = {}
    
    for i = start_line, end_line do
        table.insert(context_lines, lines[i])
    end
    
    return {
        prefix = prefix,
        cursor_line = cursor[1],
        cursor_col = cursor[2],
        buffer_content = table.concat(context_lines, "\n"),
        file_type = vim.api.nvim_buf_get_option(bufnr, "filetype"),
        file_path = vim.api.nvim_buf_get_name(bufnr),
    }
end

-- Request completion from API
function M.request_completion(context)
    if not config.get("api_key") then
        vim.notify("NeoAI: API key not configured", vim.log.levels.WARN)
        return
    end
    
    completion_state.active = true
    completion_state.context = context
    state.set_completion_active(true, context)
    
    -- Build completion request
    local prompt = M.build_completion_prompt(context)
    local completion_config = config.get_completion_config()
    
    -- Mock API call (replace with actual implementation)
    local start_time = vim.loop.hrtime() / 1e6
    completion_state.request_id = utils.generate_id()
    
    -- Simulate async API call
    vim.defer_fn(function()
        local suggestions = M.mock_completion_suggestions(context)
        local end_time = vim.loop.hrtime() / 1e6
        local response_time = end_time - start_time
        
        completion_state.suggestions = suggestions
        completion_state.current_suggestion = 0
        completion_state.active = false
        
        state.record_request(response_time)
        state.set_completion_active(false)
        
        if #suggestions > 0 then
            M.show_completion_suggestions()
        end
    end, 300)
end

-- Build completion prompt
function M.build_completion_prompt(context)
    return string.format([[
Complete the following code in %s format. The cursor is at the end of the prefix.

File: %s
Language: %s

Context:
%s

Prefix:
%s

Provide 3-5 relevant completion suggestions that are syntactically correct and contextually appropriate.
]], 
        context.file_type,
        context.file_path,
        context.file_type,
        context.buffer_content,
        context.prefix
    )
end

-- Mock completion suggestions (replace with actual API call)
function M.mock_completion_suggestions(context)
    local suggestions = {}
    
    -- Simple mock suggestions based on file type
    if context.file_type == "lua" then
        if context.prefix:match("local%s+%w+$") then
            suggestions = {" = {}", " = nil", " = function()", " = require("}
        elseif context.prefix:match("if%s+%w+$") then
            suggestions = {" then", " == nil then", " ~= nil then", " > 0 then"}
        elseif context.prefix:match("function%s+%w+$") then
            suggestions = {"()", "(arg1, arg2)", "(self)", "(...)"}
        end
    elseif context.file_type == "python" then
        if context.prefix:match("def%s+%w+$") then
            suggestions = {"():", "(self):", "(arg1, arg2):", "(*args, **kwargs):"}
        elseif context.prefix:match("if%s+%w+$") then
            suggestions = {" is None:", " == 0:", " > 0:", " in range("}
        elseif context.prefix:match("import%s+%w+$") then
            suggestions = {"", " as ", " from ", " *"}
        end
    elseif context.file_type == "javascript" or context.file_type == "typescript" then
        if context.prefix:match("const%s+%w+$") then
            suggestions = {" = {}", " = []", " = () => {}", " = new "}
        elseif context.prefix:match("function%s+%w+$") then
            suggestions = {"()", "(arg1, arg2)", "(...args)", "() {"}
        elseif context.prefix:match("if%s+%w+$") then
            suggestions = {" === null", " === undefined", " > 0", " === true"}
        end
    end
    
    -- Fallback suggestions
    if #suggestions == 0 then
        suggestions = {" ", "()", "[]", "{}", ";"}
    end
    
    return suggestions
end

-- Show completion suggestions
function M.show_completion_suggestions()
    if #completion_state.suggestions == 0 then
        return
    end
    
    local suggestion = completion_state.suggestions[completion_state.current_suggestion + 1]
    if suggestion then
        M.insert_completion(suggestion)
    end
end

-- Insert completion
function M.insert_completion(text)
    local bufnr = vim.api.nvim_get_current_buf()
    local cursor = utils.get_cursor()
    local line = cursor[1]
    local col = cursor[2]
    
    -- Insert the completion
    vim.api.nvim_buf_set_text(bufnr, line - 1, col, line - 1, col, {text})
    
    -- Move cursor to end of completion
    utils.set_cursor(line, col + #text)
end

-- Cycle through suggestions
function M.next_suggestion()
    if #completion_state.suggestions == 0 then
        return
    end
    
    completion_state.current_suggestion = (completion_state.current_suggestion + 1) % #completion_state.suggestions
    M.show_completion_suggestions()
end

function M.previous_suggestion()
    if #completion_state.suggestions == 0 then
        return
    end
    
    completion_state.current_suggestion = (completion_state.current_suggestion - 1) % #completion_state.suggestions
    if completion_state.current_suggestion < 0 then
        completion_state.current_suggestion = #completion_state.suggestions - 1
    end
    M.show_completion_suggestions()
end

-- Update context
function M.update_context()
    if completion_state.active then
        completion_state.context = M.get_completion_context()
    end
end

-- Stop completion
function M.stop()
    completion_state.active = false
    completion_state.request_id = nil
    completion_state.suggestions = {}
    completion_state.current_suggestion = 0
    state.set_completion_active(false)
end

-- Get completion state
function M.get_state()
    return vim.deepcopy(completion_state)
end

return M