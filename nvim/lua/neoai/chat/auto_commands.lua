local config = require("neoai.config")
local utils = require("neoai.utils")
local state = require("neoai.state")
local chat = require("neoai.chat")

local M = {}

-- Setup chat-specific autocommands
function M.setup()
    local augroup = vim.api.nvim_create_augroup("NeoaiChat", { clear = true })
    
    -- Auto-save chat history
    vim.api.nvim_create_autocmd({ "BufWritePre", "BufLeave" }, {
        group = augroup,
        pattern = "neoai-chat",
        callback = M._auto_save_chat,
        desc = "NeoAI: Auto-save chat history",
    })
    
    -- Handle window resize for chat
    vim.api.nvim_create_autocmd("WinResized", {
        group = augroup,
        callback = M._handle_window_resize,
        desc = "NeoAI: Handle chat window resize",
    })
    
    -- Clean up chat on VimLeave
    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = augroup,
        callback = M._cleanup_chat,
        desc = "NeoAI: Clean up chat on exit",
    })
    
    -- Update chat context on file changes
    vim.api.nvim_create_autocmd({ "BufWritePost", "TextChanged", "TextChangedI" }, {
        group = augroup,
        callback = M._update_chat_context,
        desc = "NeoAI: Update chat context on file changes",
    })
    
    -- Auto-focus chat on new messages
    vim.api.nvim_create_autocmd("User", {
        group = augroup,
        pattern = "NeoaiChatNewMessage",
        callback = M._auto_focus_chat,
        desc = "NeoAI: Auto-focus chat on new messages",
    })
end

-- Auto-save chat history
function M._auto_save_chat()
    if not chat.is_active() then
        return
    end
    
    local chat_state = chat.get_state()
    local history_file = vim.fn.stdpath("data") .. "/neoai/chat_history.json"
    
    -- Ensure directory exists
    local history_dir = vim.fn.fnamemodify(history_file, ":h")
    vim.fn.mkdir(history_dir, "p")
    
    -- Save chat history
    local history = {
        timestamp = os.time(),
        messages = chat_state.messages,
        context = chat_state.context,
    }
    
    local content = vim.json.encode(history)
    local file = io.open(history_file, "w")
    if file then
        file:write(content)
        file:close()
    else
        vim.notify("NeoAI: Failed to save chat history", vim.log.levels.WARN)
    end
end

-- Handle window resize for chat
function M._handle_window_resize()
    if not chat.is_active() then
        return
    end
    
    -- Trigger chat resize handling
    vim.defer_fn(function()
        if chat.is_active() then
            chat.handle_resize()
        end
    end, 100)
end

-- Clean up chat on exit
function M._cleanup_chat()
    if chat.is_active() then
        chat.close()
    end
end

-- Update chat context on file changes
function M._update_chat_context()
    if not chat.is_active() then
        return
    end
    
    -- Debounced context update
    local debounced_update = utils.debounce(function()
        if chat.is_active() then
            local ok, workspace = pcall(require, "neoai.workspace")
            if ok and workspace.update_context then
                workspace.update_context()
            end
        end
    end, 2000)
    
    debounced_update()
end

-- Auto-focus chat on new messages
function M._auto_focus_chat()
    if not chat.is_active() then
        return
    end
    
    local chat_state = chat.get_state()
    if not chat_state.window or not vim.api.nvim_win_is_valid(chat_state.window) then
        return
    end
    
    -- Focus chat window if user is not actively typing
    local current_win = vim.api.nvim_get_current_win()
    local current_buf = vim.api.nvim_win_get_buf(current_win)
    
    -- Don't focus if user is in insert mode or in a different file
    if vim.fn.mode() ~= "i" and current_buf ~= chat_state.buffer then
        vim.api.nvim_set_current_win(chat_state.window)
        
        -- Move cursor to end of chat
        local line_count = vim.api.nvim_buf_line_count(chat_state.buffer)
        vim.api.nvim_win_set_cursor(chat_state.window, { line_count, 0 })
    end
end

-- Setup chat buffer autocommands
function M.setup_buffer_autocommands(bufnr)
    local augroup = vim.api.nvim_create_augroup("NeoaiChatBuffer", { clear = true })
    
    -- Save chat on buffer leave
    vim.api.nvim_create_autocmd("BufLeave", {
        group = augroup,
        buffer = bufnr,
        callback = M._auto_save_chat,
        desc = "NeoAI: Save chat on buffer leave",
    })
    
    -- Handle cursor movement in chat
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = augroup,
        buffer = bufnr,
        callback = M._handle_chat_cursor_move,
        desc = "NeoAI: Handle cursor movement in chat",
    })
    
    -- Auto-scroll to bottom on new content
    vim.api.nvim_create_autocmd("TextChanged", {
        group = augroup,
        buffer = bufnr,
        callback = M._auto_scroll_to_bottom,
        desc = "NeoAI: Auto-scroll to bottom on new content",
    })
end

-- Handle cursor movement in chat
function M._handle_chat_cursor_move()
    if not chat.is_active() then
        return
    end
    
    local chat_state = chat.get_state()
    local bufnr = vim.api.nvim_get_current_buf()
    
    if bufnr ~= chat_state.buffer then
        return
    end
    
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    
    -- Prevent cursor from going into AI response area
    if cursor[1] < line_count - 1 then
        vim.api.nvim_win_set_cursor(0, { line_count - 1, cursor[2] })
    end
end

-- Auto-scroll to bottom on new content
function M._auto_scroll_to_bottom()
    if not chat.is_active() then
        return
    end
    
    local chat_state = chat.get_state()
    local bufnr = vim.api.nvim_get_current_buf()
    
    if bufnr ~= chat_state.buffer then
        return
    end
    
    local win = vim.api.nvim_get_current_win()
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    
    -- Scroll to bottom
    vim.api.nvim_win_set_cursor(win, { line_count, 0 })
end

return M
