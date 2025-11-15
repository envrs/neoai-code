local M = {}

-- Deep copy function
function M.deep_copy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[M.deep_copy(orig_key)] = M.deep_copy(orig_value)
        end
        setmetatable(copy, M.deep_copy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Check if string is empty or nil
function M.is_empty(str)
    return not str or str == "" or str:match("^%s*$")
end

-- Trim whitespace from string
function M.trim(str)
    if not str then return nil end
    return str:match("^%s*(.-)%s*$")
end

-- Split string by delimiter
function M.split(str, delimiter)
    if not str then return {} end
    local result = {}
    local pattern = string.format("([^%s]+)", delimiter)
    for match in str:gmatch(pattern) do
        table.insert(result, match)
    end
    return result
end

-- Join table elements
function M.join(tbl, separator)
    if not tbl or #tbl == 0 then return "" end
    separator = separator or ", "
    return table.concat(tbl, separator)
end

-- Check if file exists
function M.file_exists(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
end

-- Read file content
function M.read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*all")
    f:close()
    return content
end

-- Write file content
function M.write_file(path, content)
    local f = io.open(path, "w")
    if not f then return false end
    f:write(content)
    f:close()
    return true
end

-- Get file extension
function M.get_extension(filename)
    return filename:match("^.+%.(.+)$")
end

-- Check if file is code file
function M.is_code_file(filename)
    local code_extensions = {
        "lua", "py", "js", "ts", "java", "cpp", "c", "go", "rs",
        "h", "hpp", "cs", "php", "rb", "swift", "kt", "scala"
    }
    local ext = M.get_extension(filename)
    return ext and vim.tbl_contains(code_extensions, ext)
end

-- Get current buffer content
function M.get_buffer_content(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    return table.concat(lines, "\n")
end

-- Get current selection
function M.get_selection()
    local mode = vim.fn.mode()
    if mode == "v" or mode == "V" or mode == "" then
        local start_pos = vim.fn.getpos("'<")
        local end_pos = vim.fn.getpos("'>")
        local lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)
        
        if #lines == 0 then return "" end
        
        if #lines == 1 then
            return lines[1]:sub(start_pos[3], end_pos[3])
        else
            lines[1] = lines[1]:sub(start_pos[3])
            lines[#lines] = lines[#lines]:sub(1, end_pos[3])
            return table.concat(lines, "\n")
        end
    end
    return ""
end

-- Get cursor position
function M.get_cursor()
    return vim.api.nvim_win_get_cursor(0)
end

-- Set cursor position
function M.set_cursor(line, col)
    vim.api.nvim_win_set_cursor(0, {line, col})
end

-- Debounce function
function M.debounce(func, delay)
    local timer_id = nil
    return function(...)
        local args = {...}
        if timer_id then
            vim.fn.timer_stop(timer_id)
        end
        timer_id = vim.fn.timer_start(delay, function()
            func(unpack(args))
            timer_id = nil
        end)
    end
end

-- Throttle function
function M.throttle(func, delay)
    local last_time = 0
    return function(...)
        local current_time = vim.loop.hrtime() / 1e6 -- Convert to milliseconds
        if current_time - last_time >= delay then
            last_time = current_time
            return func(...)
        end
    end
end

-- Async wrapper
function M.async(func)
    return function(...)
        local args = {...}
        vim.schedule(function()
            func(unpack(args))
        end)
    end
end

-- Format time
function M.format_time(ms)
    if ms < 1000 then
        return string.format("%.0fms", ms)
    elseif ms < 60000 then
        return string.format("%.1fs", ms / 1000)
    else
        return string.format("%.1fm", ms / 60000)
    end
end

-- Generate unique ID
function M.generate_id()
    return string.format("%x", os.time() * 1000 + math.random(1000, 9999))
end

return M