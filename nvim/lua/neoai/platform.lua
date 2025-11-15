local M = {}

-- Convert command for different platforms
function M.convert_command(cmd)
    -- For now, just return the command as-is
    -- In a real implementation, this would handle platform-specific command conversion
    return cmd
end

-- Check if platform is Windows
function M.is_windows()
    return vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1
end

-- Check if platform is macOS
function M.is_mac()
    return vim.fn.has('mac') == 1 or vim.fn.has('macunix') == 1
end

-- Check if platform is Linux
function M.is_linux()
    return vim.fn.has('unix') == 1 and not M.is_mac()
end

-- Get cache directory
function M.get_cache_dir()
    local cache_dir
    
    if M.is_windows() then
        cache_dir = vim.fn.expand('$LOCALAPPDATA') .. '/NeoAI'
    elseif M.is_mac() then
        cache_dir = vim.fn.expand('$HOME') .. '/Library/Caches/neoai'
    else
        -- Linux and other Unix-like systems
        local xdg_cache = vim.fn.expand('$XDG_CACHE_HOME')
        if xdg_cache and xdg_cache ~= '' then
            cache_dir = xdg_cache .. '/neoai'
        else
            cache_dir = vim.fn.expand('$HOME') .. '/.cache/neoai'
        end
    end
    
    -- Create directory if it doesn't exist
    vim.fn.mkdir(cache_dir, 'p')
    
    return cache_dir
end

-- Get platform information
function M.get_platform_info()
    local info = {
        os = 'unknown',
        arch = 'unknown',
        platform_string = 'unknown'
    }
    
    -- Determine OS
    if M.is_windows() then
        info.os = 'windows'
    elseif M.is_mac() then
        info.os = 'mac'
    elseif M.is_linux() then
        info.os = 'linux'
    else
        info.os = 'unix'
    end
    
    -- Determine architecture
    local arch = ""
    if vim.fn.executable("uname") == 1 then
        arch = vim.fn.system('uname -m 2>/dev/null'):gsub('%s+', '')
    end
    if arch == "" then
        -- Fallback for Windows
        arch = vim.fn.getenv('PROCESSOR_ARCHITECTURE') or 'unknown'
    end
    
    if arch:match('x86_64') or arch:match('amd64') then
        info.arch = 'x64'
    elseif arch:match('i[3-6]86') then
        info.arch = 'x86'
    elseif arch:match('arm64') or arch:match('aarch64') then
        info.arch = 'arm64'
    elseif arch:match('arm') then
        info.arch = 'arm'
    else
        info.arch = arch:lower()
    end
    
    -- Create platform string
    info.platform_string = info.os .. '-' .. info.arch
    
    return info
end

return M
