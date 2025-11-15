local config = require("neoai.config")
local utils = require("neoai.utils")
local state = require("neoai.state")

local M = {}

-- Apply changes to current buffer
function M.apply_to_buffer(changes)
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    
    -- Apply changes in reverse order to maintain line numbers
    for i = #changes, 1, -1 do
        local change = changes[i]
        if change.type == "insert" then
            vim.api.nvim_buf_set_lines(bufnr, change.line - 1, change.line - 1, false, change.lines)
        elseif change.type == "replace" then
            vim.api.nvim_buf_set_lines(bufnr, change.line - 1, change.end_line, false, change.lines)
        elseif change.type == "delete" then
            vim.api.nvim_buf_set_lines(bufnr, change.line - 1, change.end_line, false, {})
        end
    end
    
    vim.notify("NeoAI: Changes applied to buffer", vim.log.levels.INFO)
end

-- Apply changes to file
function M.apply_to_file(file_path, changes)
    local lines = {}
    local file = io.open(file_path, "r")
    if file then
        lines = vim.split(file:read("*all"), "\n")
        file:close()
    else
        vim.notify("NeoAI: Cannot read file " .. file_path, vim.log.levels.ERROR)
        return false
    end
    
    -- Apply changes in reverse order
    for i = #changes, 1, -1 do
        local change = changes[i]
        if change.type == "insert" then
            for j = #change.lines, 1, -1 do
                table.insert(lines, change.line, change.lines[j])
            end
        elseif change.type == "replace" then
            for j = change.end_line, change.line, -1 do
                table.remove(lines, change.line)
            end
            for j = #change.lines, 1, -1 do
                table.insert(lines, change.line, change.lines[j])
            end
        elseif change.type == "delete" then
            for j = change.end_line, change.line, -1 do
                table.remove(lines, change.line)
            end
        end
    end
    
    -- Write back to file
    local content = table.concat(lines, "\n")
    local file = io.open(file_path, "w")
    if file then
        file:write(content)
        file:close()
        vim.notify("NeoAI: Changes applied to " .. file_path, vim.log.levels.INFO)
        return true
    else
        vim.notify("NeoAI: Failed to write to " .. file_path, vim.log.levels.ERROR)
        return false
    end
end

-- Apply suggested changes with confirmation
function M.apply_suggested_changes(suggestions, callback)
    if not suggestions or #suggestions == 0 then
        vim.notify("NeoAI: No changes to apply", vim.log.levels.WARN)
        return
    end
    
    -- Create buffer for review
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, "neoai-changes")
    vim.api.nvim_buf_set_option(buf, "filetype", "diff")
    
    -- Generate diff content
    local diff_lines = {}
    table.insert(diff_lines, "NeoAI Suggested Changes")
    table.insert(diff_lines, "========================")
    table.insert(diff_lines, "")
    
    for i, suggestion in ipairs(suggestions) do
        table.insert(diff_lines, string.format("Change %d: %s", i, suggestion.description or "No description"))
        table.insert(diff_lines, string.format("File: %s", suggestion.file_path or "Current buffer"))
        
        if suggestion.diff then
            table.insert(diff_lines, "")
            local diff_content = vim.split(suggestion.diff, "\n")
            vim.list_extend(diff_lines, diff_content)
        end
        
        table.insert(diff_lines, "")
        table.insert(diff_lines, "---")
        table.insert(diff_lines, "")
    end
    
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, diff_lines)
    
    -- Setup keymaps for the review buffer
    local opts = { noremap = true, silent = true, buffer = buf }
    vim.keymap.set("n", "a", function()
        M._apply_all_suggestions(suggestions, callback)
        vim.api.nvim_buf_delete(buf, { force = true })
    end, opts)
    
    vim.keymap.set("n", "q", function()
        vim.api.nvim_buf_delete(buf, { force = true })
    end, opts)
    
    -- Open in a new window
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = math.floor(vim.o.columns * 0.8),
        height = math.floor(vim.o.lines * 0.8),
        col = math.floor(vim.o.columns * 0.1),
        row = math.floor(vim.o.lines * 0.1),
        border = "rounded",
    })
    
    vim.api.nvim_win_set_option(win, "wrap", true)
end

-- Internal function to apply all suggestions
function M._apply_all_suggestions(suggestions, callback)
    local applied = 0
    local failed = 0
    
    for _, suggestion in ipairs(suggestions) do
        local success = false
        
        if suggestion.file_path and suggestion.file_path ~= "" then
            success = M.apply_to_file(suggestion.file_path, suggestion.changes or {})
        else
            success = pcall(M.apply_to_buffer, suggestion.changes or {})
        end
        
        if success then
            applied = applied + 1
        else
            failed = failed + 1
        end
    end
    
    local message = string.format("NeoAI: Applied %d changes", applied)
    if failed > 0 then
        message = message .. string.format(", %d failed", failed)
    end
    
    vim.notify(message, failed > 0 and vim.log.levels.WARN or vim.log.levels.INFO)
    
    if callback then
        callback(applied, failed)
    end
end

return M
