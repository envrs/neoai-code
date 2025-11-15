local consts = require("neoai.consts")
local config = require("neoai.config")
local state = require("neoai.state")
local features = require("neoai.features")
local utils = require("neoai.utils")

local M = {}

-- Setup autocommands
function M.setup()
    -- Create autocommand group
    local neoai_group = vim.api.nvim_create_augroup(consts.AUGROUPS.NEOAI, { clear = true })
    
    -- Auto-completion autocommands
    if features.is_enabled("auto_complete") then
        local completion_group = vim.api.nvim_create_augroup(consts.AUGROUPS.COMPLETION, { clear = true })
        
        -- Trigger completion on text change
        vim.api.nvim_create_autocmd("TextChangedI", {
            group = completion_group,
            callback = function()
                local completion = require("neoai.completion")
                completion.auto_trigger()
            end,
            desc = "NeoAI: Auto trigger completion",
        })
        
        -- Trigger completion on cursor moved
        vim.api.nvim_create_autocmd("CursorMovedI", {
            group = completion_group,
            callback = utils.throttle(function()
                local completion = require("neoai.completion")
                completion.update_context()
            end, 500),
            desc = "NeoAI: Update completion context",
        })
    end
    
    -- Chat interface autocommands
    if features.is_enabled("chat_interface") then
        local chat_group = vim.api.nvim_create_augroup(consts.AUGROUPS.CHAT, { clear = true })
        
        -- Close chat on buffer delete
        vim.api.nvim_create_autocmd("BufDelete", {
            group = chat_group,
            callback = function(args)
                local chat = require("neoai.chat")
                if args.buf == state.get("chat_buffer") then
                    chat.close()
                end
            end,
            desc = "NeoAI: Close chat on buffer delete",
        })
        
        -- Handle window resize for chat
        vim.api.nvim_create_autocmd("WinResized", {
            group = chat_group,
            callback = function()
                local chat = require("neoai.chat")
                chat.handle_resize()
            end,
            desc = "NeoAI: Handle chat window resize",
        })
    end
    
    -- Workspace integration autocommands
    if features.is_enabled("workspace_integration") then
        -- Update workspace files on directory change
        vim.api.nvim_create_autocmd("DirChanged", {
            group = neoai_group,
            callback = function()
                local workspace = require("neoai.workspace")
                workspace.update_workspace_files()
            end,
            desc = "NeoAI: Update workspace files on directory change",
        })
        
        -- Watch for file changes
        vim.api.nvim_create_autocmd("BufWritePost", {
            group = neoai_group,
            callback = function(args)
                local workspace = require("neoai.workspace")
                workspace.on_file_changed(args.file)
            end,
            desc = "NeoAI: Handle file changes",
        })
        
        -- Update context on buffer enter
        vim.api.nvim_create_autocmd("BufEnter", {
            group = neoai_group,
            callback = function()
                local workspace = require("neoai.workspace")
                workspace.update_context()
            end,
            desc = "NeoAI: Update context on buffer enter",
        })
    end
    
    -- LSP integration autocommands
    if features.is_enabled("lsp_integration") then
        -- Setup LSP when it attaches
        vim.api.nvim_create_autocmd("LspAttach", {
            group = neoai_group,
            callback = function(args)
                local lsp = require("neoai.lsp")
                lsp.on_attach(args.data, args.buf)
            end,
            desc = "NeoAI: Setup LSP integration",
        })
        
        -- Handle LSP detach
        vim.api.nvim_create_autocmd("LspDetach", {
            group = neoai_group,
            callback = function(args)
                local lsp = require("neoai.lsp")
                lsp.on_detach(args.data, args.buf)
            end,
            desc = "NeoAI: Cleanup LSP integration",
        })
    end
    
    -- Plugin cleanup on exit
    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = neoai_group,
        callback = function()
            M.cleanup()
        end,
        desc = "NeoAI: Cleanup on exit",
    })
    
    vim.notify("NeoAI: Autocommands setup complete", vim.log.levels.DEBUG)
end

-- Cleanup function
function M.cleanup()
    -- Close chat if active
    if state.get("chat_active") then
        local chat = require("neoai.chat")
        chat.close()
    end
    
    -- Stop completion if active
    if state.get("completion_active") then
        local completion = require("neoai.completion")
        completion.stop()
    end
    
    -- Clear state
    state.reset()
    
    vim.notify("NeoAI: Cleanup complete", vim.log.levels.DEBUG)
end

-- Get autocommand group info
function M.get_group_info()
    local groups = {
        consts.AUGROUPS.NEOAI,
        consts.AUGROUPS.COMPLETION,
        consts.AUGROUPS.CHAT,
    }
    
    local info = {}
    for _, group in ipairs(groups) do
        local autocmds = vim.api.nvim_get_autocmds({ group = group })
        if #autocmds > 0 then
            info[group] = {
                count = #autocmds,
                autocmds = autocmds,
            }
        end
    end
    
    return info
end

return M