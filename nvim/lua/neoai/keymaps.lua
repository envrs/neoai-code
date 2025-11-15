local consts = require("neoai.consts")
local config = require("neoai.config")
local features = require("neoai.features")
local user_commands = require("neoai.user_commands")

local M = {}

-- Keymap storage for cleanup
local neoai_keymaps = {}

-- Default keymap definitions
local default_keymaps = {
    -- Chat interface
    {
        mode = "n",
        lhs = "<leader>ac",
        rhs = function()
            local chat = require("neoai.chat")
            chat.toggle()
        end,
        opts = { desc = "NeoAI Chat", silent = true },
    },
    
    -- Trigger completion
    {
        mode = "i",
        lhs = "<C-g>",
        rhs = function()
            local completion = require("neoai.completion")
            completion.trigger_completion()
        end,
        opts = { desc = "NeoAI Complete", silent = true },
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
        opts = { desc = "NeoAI Toggle Feature", silent = true },
    },
    
    -- Show status
    {
        mode = "n",
        lhs = "<leader>as",
        rhs = function()
            user_commands.execute(consts.COMMANDS.STATUS, {})
        end,
        opts = { desc = "NeoAI Status", silent = true },
    },
    
    -- Configuration
    {
        mode = "n",
        lhs = "<leader>acfg",
        rhs = function()
            user_commands.execute(consts.COMMANDS.CONFIG, { args = "show" })
        end,
        opts = { desc = "NeoAI Show Config", silent = true },
    },
}

-- Check if keymap would conflict
local function has_keymap_conflict(mode, lhs, buffer)
    local keymaps = vim.api.nvim_buf_get_keymap(buffer or 0, mode)
    for _, keymap in ipairs(keymaps) do
        if keymap.lhs == lhs then
            return true, keymap
        end
    end
    
    -- Also check global keymaps
    if not buffer then
        local global_keymaps = vim.api.nvim_get_keymap(mode)
        for _, keymap in ipairs(global_keymaps) do
            if keymap.lhs == lhs then
                return true, keymap
            end
        end
    end
    
    return false
end

-- Safe keymap setter with conflict detection
local function safe_set_keymap(mode, lhs, rhs, opts, buffer)
    local keymap_config = config.get().keymaps or {}
    local has_conflict, existing_keymap = has_keymap_conflict(mode, lhs, buffer)
    
    if has_conflict then
        -- Check if it's our own keymap
        local is_ours = existing_keymap.desc and existing_keymap.desc:match("NeoAI")
        if not is_ours then
            if not keymap_config.override_conflicts then
                if keymap_config.show_conflict_warnings ~= false then
                    vim.notify(
                        string.format("NeoAI: Keymap conflict detected - %s %s is already mapped to '%s'", 
                            mode, lhs, existing_keymap.desc or existing_keymap.rhs or "unknown"),
                        vim.log.levels.WARN
                    )
                end
                return false
            end
        end
    end
    
    -- Set the keymap
    local success, err = pcall(function()
        if buffer then
            vim.api.nvim_buf_set_keymap(buffer or 0, mode, lhs, "", {
                callback = rhs,
                desc = opts.desc,
                silent = opts.silent ~= false,
                noremap = opts.noremap ~= false,
                expr = opts.expr or false,
                nowait = opts.nowait or false,
            })
        else
            vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", opts, {
                buffer = buffer,
            }))
        end
    end)
    
    if success then
        -- Store for cleanup
        table.insert(neoai_keymaps, {
            mode = mode,
            lhs = lhs,
            buffer = buffer,
        })
        return true
    else
        vim.notify("NeoAI: Failed to set keymap " .. lhs .. ": " .. err, vim.log.levels.ERROR)
        return false
    end
end

-- Setup keymaps with conflict detection
function M.setup()
    -- Check if keymaps are enabled
    local keymap_config = config.get().keymaps or {}
    if not keymap_config.enabled then
        vim.notify("NeoAI: Keymaps are disabled", vim.log.levels.DEBUG)
        return
    end
    
    -- Clear existing NeoAI keymaps first
    M.clear()
    
    local setup_count = 0
    local conflict_count = 0
    
    -- Apply default keymaps
    for _, keymap in ipairs(default_keymaps) do
        if safe_set_keymap(keymap.mode, keymap.lhs, keymap.rhs, keymap.opts) then
            setup_count = setup_count + 1
        else
            conflict_count = conflict_count + 1
        end
    end
    
    -- Apply custom keymaps from config
    if keymap_config.custom_keymaps then
        for _, keymap in ipairs(keymap_config.custom_keymaps) do
            if safe_set_keymap(keymap.mode, keymap.lhs, keymap.rhs, keymap.opts) then
                setup_count = setup_count + 1
            else
                conflict_count = conflict_count + 1
            end
        end
    end
    
    local message = string.format("NeoAI: Keymaps setup complete - %d set, %d conflicts", 
        setup_count, conflict_count)
    
    if conflict_count > 0 then
        vim.notify(message, vim.log.levels.WARN)
    else
        vim.notify(message, vim.log.levels.DEBUG)
    end
end

-- Add a custom keymap
function M.add_keymap(keymap)
    if not keymap.mode or not keymap.lhs or not keymap.rhs then
        vim.notify("NeoAI: Invalid keymap definition", vim.log.levels.ERROR)
        return false
    end
    
    return safe_set_keymap(keymap.mode, keymap.lhs, keymap.rhs, keymap.opts, keymap.buffer)
end

-- Remove a specific keymap
function M.remove_keymap(mode, lhs, buffer)
    local success = pcall(function
        if buffer then
            vim.api.nvim_buf_del_keymap(buffer or 0, mode, lhs)
        else
            vim.keymap.del(mode, lhs, { buffer = buffer })
        end
    end)
    
    if success then
        -- Remove from storage
        for i, stored_keymap in ipairs(neoai_keymaps) do
            if stored_keymap.mode == mode and stored_keymap.lhs == lhs and stored_keymap.buffer == buffer then
                table.remove(neoai_keymaps, i)
                break
            end
        end
    end
    
    return success
end

-- Clear all NeoAI keymaps
function M.clear()
    local cleared = 0
    
    -- Clear in reverse order to avoid issues
    for i = #neoai_keymaps, 1, -1 do
        local keymap = neoai_keymaps[i]
        if M.remove_keymap(keymap.mode, keymap.lhs, keymap.buffer) then
            cleared = cleared + 1
        end
        table.remove(neoai_keymaps, i)
    end
    
    if cleared > 0 then
        vim.notify("NeoAI: Cleared " .. cleared .. " keymaps", vim.log.levels.DEBUG)
    end
end

-- Check if a keymap exists
function M.has_keymap(mode, lhs, buffer)
    return has_keymap_conflict(mode, lhs, buffer)
end

-- Get all NeoAI keymaps
function M.get_keymaps()
    return vim.deepcopy(neoai_keymaps)
end

-- Check for potential conflicts before setup
function M.check_conflicts()
    local conflicts = {}
    
    for _, keymap in ipairs(default_keymaps) do
        local has_conflict, existing_keymap = has_keymap_conflict(keymap.mode, keymap.lhs)
        if has_conflict then
            local is_ours = existing_keymap.desc and existing_keymap.desc:match("NeoAI")
            if not is_ours then
                table.insert(conflicts, {
                    mode = keymap.mode,
                    lhs = keymap.lhs,
                    existing = existing_keymap.desc or existing_keymap.rhs or "unknown",
                })
            end
        end
    end
    
    return conflicts
end

-- Show keymap status
function M.show_status()
    local conflicts = M.check_conflicts()
    local keymaps = M.get_keymaps()
    
    local status = string.format([[
NeoAI Keymap Status:
- Active keymaps: %d
- Conflicts: %d
]], #keymaps, #conflicts)
    
    if #conflicts > 0 then
        status = status .. "\nConflicts:\n"
        for _, conflict in ipairs(conflicts) do
            status = status .. string.format("  %s %s -> %s\n", conflict.mode, conflict.lhs, conflict.existing)
        end
    end
    
    vim.notify(status, vim.log.levels.INFO)
end

return M