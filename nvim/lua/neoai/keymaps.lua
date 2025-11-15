local consts = require("neoai.consts")
local config = require("neoai.config")
local features = require("neoai.features")
local user_commands = require("neoai.user_commands")

local M = {}

-- Default keymaps
local default_keymaps = {
    -- Chat interface
    {
        mode = "n",
        lhs = "<leader>ac",
        rhs = consts.COMMANDS.CHAT,
        opts = { desc = "NeoAI Chat" },
    },
    
    -- Trigger completion
    {
        mode = "i",
        lhs = "<C-g>",
        rhs = consts.COMMANDS.COMPLETE,
        opts = { desc = "NeoAI Complete" },
    },
    
    -- Toggle features
    {
        mode = "n",
        lhs = "<leader>at",
        rhs = function()
            vim.ui.select(features.get_all(), {
                prompt = "Toggle NeoAI Feature:",
                format_item = function(item)
                    local status = features.is_enabled(item) and "✓" or "✗"
                    return status .. " " .. item
                end,
            }, function(choice)
                if choice then
                    features.toggle(choice)
                end
            end)
        end,
        opts = { desc = "NeoAI Toggle Feature" },
    },
    
    -- Show status
    {
        mode = "n",
        lhs = "<leader>as",
        rhs = consts.COMMANDS.STATUS,
        opts = { desc = "NeoAI Status" },
    },
    
    -- Configuration
    {
        mode = "n",
        lhs = "<leader>acfg",
        rhs = consts.COMMANDS.CONFIG .. " show",
        opts = { desc = "NeoAI Show Config" },
    },
}

-- User keymaps registry
local user_keymaps = {}

-- Setup default keymaps
function M.setup()
    -- Clear existing keymaps
    M.clear()
    
    -- Apply default keymaps
    for _, keymap in ipairs(default_keymaps) do
        M.set(keymap.mode, keymap.lhs, keymap.rhs, keymap.opts)
    end
    
    -- Apply user keymaps
    for _, keymap in ipairs(user_keymaps) do
        M.set(keymap.mode, keymap.lhs, keymap.rhs, keymap.opts)
    end
    
    vim.notify("NeoAI: Keymaps setup complete", vim.log.levels.DEBUG)
end

-- Set a keymap
function M.set(mode, lhs, rhs, opts)
    opts = opts or {}
    
    -- Handle function RHS
    if type(rhs) == "function" then
        vim.keymap.set(mode, lhs, rhs, opts)
    else
        -- Handle command RHS
        local cmd = type(rhs) == "string" and rhs or consts.COMMANDS.CHAT
        vim.keymap.set(mode, lhs, function()
            user_commands.execute(cmd:gsub("^" .. consts.COMMANDS.CHAT .. " ", ""), { args = cmd:match("^.+%s+(.+)$") })
        end, opts)
    end
end

-- Remove a keymap
function M.remove(mode, lhs)
    vim.keymap.del(mode, lhs)
end

-- Clear all NeoAI keymaps
function M.clear()
    for _, keymap in ipairs(default_keymaps) do
        pcall(vim.keymap.del, keymap.mode, keymap.lhs)
    end
    
    for _, keymap in ipairs(user_keymaps) do
        pcall(vim.keymap.del, keymap.mode, keymap.lhs)
    end
end

-- Add user keymap
function M.add_user_keymap(keymap)
    table.insert(user_keymaps, keymap)
end

-- Get all keymaps
function M.get_keymaps()
    local all_keymaps = {}
    vim.list_extend(all_keymaps, default_keymaps)
    vim.list_extend(all_keymaps, user_keymaps)
    return all_keymaps
end

-- Check if keymap exists
function M.has_keymap(mode, lhs)
    local keymaps = vim.api.nvim_get_keymap(mode)
    for _, keymap in ipairs(keymaps) do
        if keymap.lhs == lhs then
            return true
        end
    end
    return false
end

return M