local binary = require("neoai.binary")
local platform = require("neoai.platform")
local utils = require("neoai.utils")

local M = {}

-- Chat binary specific configurations
local CHAT_BINARIES = {
    "neoai_chat",
    "neoai-chat",
}

-- Find chat binary with platform-specific preferences
function M.find_chat_binary()
    local candidates = CHAT_BINARIES
    if platform.is_windows() then
        candidates = {"neoai_chat.exe", "neoai-chat.exe"}
    end

    for _, binary_name in ipairs(candidates) do
        local path = binary.find_binary(binary_name)
        if path then
            return path
        end
    end

    return nil
end

-- Check if chat binary is available
function M.is_available()
    return M.find_chat_binary() ~= nil
end

-- Get chat binary version
function M.get_version()
    local path = M.find_chat_binary()
    if not path then
        return nil
    end

    local cmd = platform.convert_command({path, "--version"})
    local result = vim.fn.system(cmd)

    if vim.v.shell_error == 0 then
        return vim.trim(result)
    end

    return nil
end

-- Validate chat binary
function M.validate()
    local path = M.find_chat_binary()
    if not path then
        return false, "Chat binary not found"
    end

    if not utils.file_exists(path) or vim.fn.executable(path) == 0 then
        return false, "Chat binary is not an executable file: " .. path
    end

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

    local valid, err = M.validate()
    local version = valid and M.get_version() or nil

    return {
        available = valid,
        path = path,
        version = version,
        error = valid and nil or err,
    }
end

return M
