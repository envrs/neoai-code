local consts = require("neoai.consts")
local config = require("neoai.config")
local state = require("neoai.state")
local features = require("neoai.features")
local utils = require("neoai.utils")
local workspace = require("neoai.workspace")

local M = {}

-- Chat state
local chat_state = {
    buffer = nil,
    window = nil,
    active = false,
    messages = {},
    context = nil,
}

-- Chat window configuration
local chat_config = {
    width = 80,
    height = 20,
    border = "single",
    style = "minimal",
}

-- Toggle chat interface
function M.toggle()
    if chat_state.active then
        M.close()
    else
        M.open()
    end
end

-- Open chat interface
function M.open()
    if chat_state.active then
        return
    end
    
    if not features.is_enabled("chat_interface") then
        vim.notify("NeoAI: Chat interface is disabled", vim.log.levels.WARN)
        return
    end
    
    -- Create chat buffer
    chat_state.buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(chat_state.buffer, "neoai-chat")
    vim.api.nvim_buf_set_option(chat_state.buffer, "filetype", "neoai-chat")
    vim.api.nvim_buf_set_option(chat_state.buffer, "buftype", "nofile")
    
    -- Setup buffer content
    M.setup_buffer()
    
    -- Create chat window
    local win_config = M.get_window_config()
    chat_state.window = vim.api.nvim_open_win(chat_state.buffer, true, win_config)
    
    -- Setup window
    M.setup_window()
    
    -- Update state
    chat_state.active = true
    state.set_chat_active(true, chat_state.buffer, chat_state.window)
    
    -- Get context
    chat_state.context = workspace.get_context(20, 5000)
    
    vim.notify("NeoAI: Chat opened", vim.log.levels.DEBUG)
end

-- Close chat interface
function M.close()
    if not chat_state.active then
        return
    end
    
    -- Close window
    if chat_state.window and vim.api.nvim_win_is_valid(chat_state.window) then
        vim.api.nvim_win_close(chat_state.window, true)
    end
    
    -- Delete buffer
    if chat_state.buffer and vim.api.nvim_buf_is_valid(chat_state.buffer) then
        vim.api.nvim_buf_delete(chat_state.buffer, { force = true })
    end
    
    -- Reset state
    chat_state.buffer = nil
    chat_state.window = nil
    chat_state.active = false
    chat_state.messages = {}
    chat_state.context = nil
    
    state.set_chat_active(false)
    
    vim.notify("NeoAI: Chat closed", vim.log.levels.DEBUG)
end

-- Get window configuration
function M.get_window_config()
    local ui = vim.api.nvim_list_uis()[1]
    local width = math.min(chat_config.width, ui.width - 10)
    local height = math.min(chat_config.height, ui.height - 10)
    
    return {
        relative = "editor",
        width = width,
        height = height,
        col = math.floor((ui.width - width) / 2),
        row = math.floor((ui.height - height) / 2),
        border = chat_config.border,
        style = chat_config.style,
        title = " NeoAI Chat ",
        title_pos = "center",
    }
end

-- Setup buffer
function M.setup_buffer()
    local lines = {
        "Welcome to NeoAI Chat!",
        "",
        "Commands:",
        "  <Enter>  - Send message",
        "  <C-c>    - Clear chat",
        "  <C-w>    - Close chat",
        "  <Tab>    - Insert current file",
        "  <C-r>    - Insert selection",
        "",
        "────────────────────────────────────────",
        "",
    }
    
    vim.api.nvim_buf_set_lines(chat_state.buffer, 0, -1, false, lines)
    
    -- Set up buffer keymaps
    local opts = { buffer = chat_state.buffer, silent = true }
    
    vim.keymap.set("n", "<Enter>", M.send_message, opts)
    vim.keymap.set("i", "<Enter>", M.send_message, opts)
    vim.keymap.set("n", "<C-c>", M.clear_chat, opts)
    vim.keymap.set("i", "<C-c>", M.clear_chat, opts)
    vim.keymap.set("n", "<C-w>", M.close, opts)
    vim.keymap.set("i", "<C-w>", M.close, opts)
    vim.keymap.set("i", "<Tab>", M.insert_current_file, opts)
    vim.keymap.set("i", "<C-r>", M.insert_selection, opts)
    
    -- Set up autocommands for buffer
    local augroup = vim.api.nvim_create_augroup("NeoaiChat", { clear = true })
    vim.api.nvim_create_autocmd("BufWinLeave", {
        group = augroup,
        buffer = chat_state.buffer,
        callback = M.close,
        desc = "NeoAI: Close chat on window leave",
    })
end

-- Setup window
function M.setup_window()
    -- Set window options
    vim.api.nvim_win_set_option(chat_state.window, "wrap", true)
    vim.api.nvim_win_set_option(chat_state.window, "linebreak", true)
    vim.api.nvim_win_set_option(chat_state.window, "cursorline", true)
    
    -- Move cursor to end of buffer
    local line_count = vim.api.nvim_buf_line_count(chat_state.buffer)
    vim.api.nvim_win_set_cursor(chat_state.window, { line_count, 0 })
end

-- Send message
function M.send_message()
    local lines = vim.api.nvim_buf_get_lines(chat_state.buffer, 0, -1, false)
    local last_line = lines[#lines]
    
    if utils.trim(last_line) == "" then
        return
    end
    
    -- Add user message
    local user_message = {
        role = "user",
        content = last_line,
        timestamp = os.time(),
    }
    
    table.insert(chat_state.messages, user_message)
    
    -- Update buffer
    M.add_message_to_buffer("You: " .. last_line)
    M.add_message_to_buffer("NeoAI: ")
    
    -- Move cursor to end
    local line_count = vim.api.nvim_buf_line_count(chat_state.buffer)
    vim.api.nvim_win_set_cursor(chat_state.window, { line_count, 0 })
    
    -- Get AI response
    M.get_ai_response(last_line)
end

-- Add message to buffer
function M.add_message_to_buffer(text)
    local lines = vim.split(text, "\n")
    local current_lines = vim.api.nvim_buf_get_lines(chat_state.buffer, 0, -1, false)
    
    -- Replace last empty line with message
    current_lines[#current_lines] = lines[1]
    
    -- Add remaining lines
    for i = 2, #lines do
        table.insert(current_lines, lines[i])
    end
    
    -- Add empty line for next input
    table.insert(current_lines, "")
    
    vim.api.nvim_buf_set_lines(chat_state.buffer, 0, -1, false, current_lines)
end

-- Get AI response
function M.get_ai_response(message)
    local start_time = vim.loop.hrtime() / 1e6
    
    -- Build context for AI
    local context = M.build_ai_context(message)
    
    -- Mock AI response (replace with actual API call)
    vim.defer_fn(function()
        local response = M.mock_ai_response(message, context)
        local end_time = vim.loop.hrtime() / 1e6
        local response_time = end_time - start_time
        
        -- Add AI message
        local ai_message = {
            role = "assistant",
            content = response,
            timestamp = os.time(),
        }
        
        table.insert(chat_state.messages, ai_message)
        
        -- Update buffer
        M.add_message_to_buffer(response)
        
        -- Record metrics
        state.record_request(response_time)
        
        -- Move cursor to end
        local line_count = vim.api.nvim_buf_line_count(chat_state.buffer)
        vim.api.nvim_win_set_cursor(chat_state.window, { line_count, 0 })
    end, 1000)
end

-- Build AI context
function M.build_ai_context(message)
    local context = {
        current_file = vim.api.nvim_buf_get_name(0),
        file_type = vim.api.nvim_buf_get_option(0, "filetype"),
        workspace_root = state.get("workspace_root"),
        messages = chat_state.messages,
        workspace_context = chat_state.context,
    }
    
    return context
end

-- Mock AI response (replace with actual API call)
function M.mock_ai_response(message, context)
    local responses = {
        "I understand your question. Let me help you with that.",
        "That's an interesting point. Here's what I think...",
        "Based on the context, I would suggest the following approach:",
        "I can help you with that. Let me analyze the code first.",
        "Great question! Here's my analysis:",
    }
    
    local base_response = responses[math.random(#responses)]
    
    -- Add context-specific responses
    if message:lower():match("help") then
        base_response = base_response .. "\n\nI can help you with:\n- Code completion\n- Code explanation\n- Bug fixing\n- Refactoring\n- Documentation"
    elseif message:lower():match("code") then
        base_response = base_response .. "\n\nI can see you're working with " .. (context.file_type or "unknown") .. " files."
        if context.workspace_context and context.workspace_context.current_file then
            base_response = base_response .. "\nCurrent file: " .. context.workspace_context.current_file
        end
    elseif message:lower():match("error") then
        base_response = base_response .. "\n\nTo help you debug, please share the error message and relevant code."
    end
    
    return base_response
end

-- Clear chat
function M.clear_chat()
    chat_state.messages = {}
    
    -- Reset buffer
    local lines = {
        "Chat cleared.",
        "",
        "────────────────────────────────────────",
        "",
    }
    
    vim.api.nvim_buf_set_lines(chat_state.buffer, 0, -1, false, lines)
    
    -- Move cursor to end
    local line_count = vim.api.nvim_buf_line_count(chat_state.buffer)
    vim.api.nvim_win_set_cursor(chat_state.window, { line_count, 0 })
    
    vim.notify("NeoAI: Chat cleared", vim.log.levels.DEBUG)
end

-- Insert current file
function M.insert_current_file()
    local current_file = vim.api.nvim_buf_get_name(0)
    local content = utils.get_buffer_content()
    
    local file_info = string.format("\n--- File: %s ---\n%s\n--- End of file ---\n", current_file, content)
    
    local lines = vim.split(file_info, "\n")
    local current_lines = vim.api.nvim_buf_get_lines(chat_state.buffer, 0, -1, false)
    local last_line = current_lines[#current_lines]
    
    -- Insert file content before last line
    current_lines[#current_lines] = lines[1]
    for i = 2, #lines do
        table.insert(current_lines, #current_lines, lines[i])
    end
    
    vim.api.nvim_buf_set_lines(chat_state.buffer, 0, -1, false, current_lines)
    
    -- Move cursor to end
    local line_count = vim.api.nvim_buf_line_count(chat_state.buffer)
    vim.api.nvim_win_set_cursor(chat_state.window, { line_count, 0 })
end

-- Insert selection
function M.insert_selection()
    local selection = utils.get_selection()
    if utils.trim(selection) == "" then
        vim.notify("NeoAI: No selection found", vim.log.levels.WARN)
        return
    end
    
    local selection_info = string.format("\n--- Selection ---\n%s\n--- End of selection ---\n", selection)
    
    local lines = vim.split(selection_info, "\n")
    local current_lines = vim.api.nvim_buf_get_lines(chat_state.buffer, 0, -1, false)
    local last_line = current_lines[#current_lines]
    
    -- Insert selection before last line
    current_lines[#current_lines] = lines[1]
    for i = 2, #lines do
        table.insert(current_lines, #current_lines, lines[i])
    end
    
    vim.api.nvim_buf_set_lines(chat_state.buffer, 0, -1, false, current_lines)
    
    -- Move cursor to end
    local line_count = vim.api.nvim_buf_line_count(chat_state.buffer)
    vim.api.nvim_win_set_cursor(chat_state.window, { line_count, 0 })
end

-- Handle window resize
function M.handle_resize()
    if not chat_state.active or not chat_state.window then
        return
    end
    
    local win_config = M.get_window_config()
    vim.api.nvim_win_set_config(chat_state.window, win_config)
end

-- Get chat state
function M.get_state()
    return vim.deepcopy(chat_state)
end

-- Check if chat is active
function M.is_active()
    return chat_state.active
end

return M
