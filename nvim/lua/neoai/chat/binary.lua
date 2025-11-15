local binary = require("neoai.binary")
local platform = require("neoai.platform")
local utils = require("neoai.utils")

local M = {}

-- Chat binary specific configurations
local CHAT_BINARIES = {
    "neoai_chat",
    "neoai-chat",
    "neoai_chat.exe",
}

-- Chat binary state
local binary_state = {
    path = nil,
    version = nil,
    available = false,
    last_check = 0,
    running = false,
    port = nil,
    process_id = nil,
    last_error = nil,
}

-- Find chat binary with platform-specific preferences
function M.find_chat_binary()
    -- Check cache first (cache for 30 seconds)
    local current_time = os.time()
    if binary_state.last_check > 0 and (current_time - binary_state.last_check) < 30 then
        return binary_state.path
    end
    
    -- Try different binary names based on platform
    local candidates = CHAT_BINARIES
    
    if platform.is_windows() then
        -- Prefer .exe on Windows
        candidates = {"neoai_chat.exe", "neoai-chat.exe", "neoai_chat"}
    elseif platform.is_mac() then
        -- Check common macOS locations
        local mac_locations = {
            "/usr/local/bin/neoai_chat",
            "/opt/homebrew/bin/neoai_chat",
            vim.fn.expand("~/.local/bin/neoai_chat"),
        }
        
        for _, location in ipairs(mac_locations) do
            if utils.file_exists(location) and vim.fn.executable(location) == 1 then
                binary_state.path = location
                binary_state.available = true
                binary_state.last_check = current_time
                return location
            end
        end
    end
    
    -- Try system PATH
    for _, binary_name in ipairs(candidates) do
        local path = binary.find_binary(binary_name)
        if path then
            binary_state.path = path
            binary_state.available = true
            binary_state.last_check = current_time
            return path
        end
    end
    
    -- Not found
    binary_state.path = nil
    binary_state.available = false
    binary_state.last_check = current_time
    return nil
end

-- Check if chat binary is available
function M.is_available()
    local path = M.find_chat_binary()
    return path ~= nil
end

-- Get chat binary version
function M.get_version()
    local path = M.find_chat_binary()
    if not path then
        return nil
    end
    
    -- Check cache
    if binary_state.version then
        return binary_state.version
    end
    
    -- Try to get version
    local cmd = platform.convert_command({path, "--version"})
    local result = vim.fn.system(cmd)
    
    if vim.v.shell_error == 0 then
        binary_state.version = vim.trim(result)
        return binary_state.version
    end
    
    return nil
end

-- Validate chat binary
function M.validate()
    local path = M.find_chat_binary()
    if not path then
        return false, "Chat binary not found"
    end
    
    -- Check if file exists
    if not utils.file_exists(path) then
        return false, "Chat binary file does not exist: " .. path
    end
    
    -- Check if executable
    if vim.fn.executable(path) == 0 then
        return false, "Chat binary is not executable: " .. path
    end
    
    -- Try to run --help to validate it's the correct binary
    local cmd = platform.convert_command({path, "--help"})
    local result = vim.fn.system(cmd)
    
    if vim.v.shell_error == 0 and result:match("NeoAI") then
        return true, path
    end
    
    return false, "Invalid chat binary: " .. path
end

-- Get chat binary info
function M.get_info()
    local path = M.find_chat_binary()
    if not path then
        return {
            available = false,
            path = nil,
            version = nil,
            error = "Chat binary not found",
        }
    end
    
    local valid, error = M.validate()
    local version = nil
    
    if valid then
        version = M.get_version()
    end
    
    return {
        available = valid,
        path = path,
        version = version,
        error = valid and nil or error,
    }
end

-- Install chat binary (placeholder for future implementation)
function M.install()
    vim.notify("NeoAI: Chat binary installation not yet implemented", vim.log.levels.WARN)
    vim.notify("NeoAI: Please install the chat binary manually", vim.log.levels.INFO)
    return false
end

-- Update chat binary (placeholder for future implementation)
function M.update()
    local path = M.find_chat_binary()
    if not path then
        vim.notify("NeoAI: Chat binary not found, cannot update", vim.log.levels.ERROR)
        return false
    end
    
    vim.notify("NeoAI: Chat binary update not yet implemented", vim.log.levels.WARN)
    return false
end

-- Get installation instructions
function M.get_install_instructions()
    local instructions = {
        "To install the NeoAI chat binary:",
        "",
        "1. Download from: https://github.com/neopilot/neoai/releases",
        "2. Extract to a directory in your PATH",
        "3. Make sure the binary is executable",
        "",
        "Platform-specific instructions:",
        "",
        "macOS:",
        "  brew install neoai-chat",
        "  OR download from releases and place in /usr/local/bin/",
        "",
        "Linux:",
        "  sudo apt install neoai-chat",
        "  OR download from releases and place in /usr/local/bin/",
        "",
        "Windows:",
        "  Download from releases and place in a directory in PATH",
        "  OR use: scoop install neoai-chat",
        "",
        "After installation, restart Neovim to detect the binary.",
    }
    
    return table.concat(instructions, "\n")
end

-- Clear cache
function M.clear_cache()
    binary_state.path = nil
    binary_state.version = nil
    binary_state.available = false
    binary_state.last_check = 0
end

-- Start chat binary
function M.start()
    local path = M.find_chat_binary()
    if not path then
        binary_state.last_error = "Chat binary not found"
        return false, nil
    end
    
    -- For now, just simulate starting
    -- In a real implementation, this would start the binary process
    binary_state.running = true
    binary_state.port = 8080
    binary_state.process_id = math.random(1000, 9999)
    binary_state.last_error = nil
    
    return true, binary_state.port
end

-- Stop chat binary
function M.stop()
    binary_state.running = false
    binary_state.port = nil
    binary_state.process_id = nil
end

-- Restart chat binary
function M.restart()
    M.stop()
    return M.start()
end

-- Get binary state
function M.get_state()
    return {
        running = binary_state.running,
        port = binary_state.port,
        process_id = binary_state.process_id,
        last_error = binary_state.last_error,
    }
end

-- Check if binary is running
function M.is_running()
    return binary_state.running
end

-- Get port
function M.get_port()
    return binary_state.port
end

-- Get last error
function M.get_last_error()
    return binary_state.last_error
end

-- Check availability (with more info)
function M.check_availability()
    local path = M.find_chat_binary()
    if path then
        return true, { path = path, version = M.get_version() }
    else
        return false, { error = "Chat binary not found" }
    end
end

-- Register event handler
function M.register_event(event_name, handler)
    -- Store event handlers for later use
    if not M.event_handlers then
        M.event_handlers = {}
    end
    M.event_handlers[event_name] = handler
end

-- Post message to chat binary
function M.post_message(message)
    -- For now, just simulate posting messages
    -- In a real implementation, this would send messages to the binary
    if M.event_handlers and M.event_handlers[message.command] then
        M.event_handlers[message.command](message.data)
    end
end

-- Check if chat binary is open
function M.is_open()
    return M.is_running()
end

-- Close chat binary
function M.close()
    M.stop()
end

-- Check if chat binary is available
function M.available()
    return M.is_available()
end

return M
