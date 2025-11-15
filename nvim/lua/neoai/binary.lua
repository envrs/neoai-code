local M = {}

-- Binary path cache
local binary_cache = {}

-- Find binary in system PATH
function M.find_binary(name)
    if binary_cache[name] then
        return binary_cache[name]
    end
    
    local path = vim.fn.exepath(name)
    if path and path ~= "" then
        binary_cache[name] = path
        return path
    end
    
    return nil
end

-- Check if binary is available
function M.is_available(name)
    return M.find_binary(name) ~= nil
end

-- Execute binary command
function M.execute(name, args, opts)
    opts = opts or {}
    local binary_path = M.find_binary(name)
    
    if not binary_path then
        error("Binary not found: " .. name)
    end
    
    local cmd = {binary_path}
    if args then
        vim.list_extend(cmd, args)
    end
    
    local result = vim.fn.system(cmd)
    
    if opts.check_exit and vim.v.shell_error ~= 0 then
        error("Command failed: " .. table.concat(cmd, " ") .. "\n" .. result)
    end
    
    return result
end

-- Execute binary asynchronously
function M.execute_async(name, args, opts, callback)
    opts = opts or {}
    local binary_path = M.find_binary(name)
    
    if not binary_path then
        if callback then
            callback(nil, "Binary not found: " .. name)
        end
        return
    end
    
    local cmd = {binary_path}
    if args then
        vim.list_extend(cmd, args)
    end
    
    vim.fn.jobstart(cmd, {
        on_stdout = opts.on_stdout,
        on_stderr = opts.on_stderr,
        on_exit = function(job_id, exit_code)
            local success = exit_code == 0
            if callback then
                callback(success, success and "Success" or "Exit code: " .. exit_code)
            end
        end,
    })
end

-- Get binary version
function M.get_version(name, version_flag)
    version_flag = version_flag or "--version"
    
    local binary_path = M.find_binary(name)
    if not binary_path then
        return nil
    end
    
    local success, result = pcall(function()
        return M.execute(name, {version_flag})
    end)
    
    if success then
        return result:match("(%d+%.%d+%.%d+)") or result:match("(%d+%.%d+)") or result
    end
    
    return nil
end

-- List all available binaries
function M.list_available(binaries)
    local available = {}
    
    for _, binary in ipairs(binaries) do
        if M.is_available(binary) then
            local version = M.get_version(binary)
            table.insert(available, {
                name = binary,
                path = M.find_binary(binary),
                version = version,
            })
        end
    end
    
    return available
end

-- Clear binary cache
function M.clear_cache()
    binary_cache = {}
end

return M