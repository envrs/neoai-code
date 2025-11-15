local config = require("neoai.config")
local utils = require("neoai.utils")
local state = require("neoai.state")

local M = {}

-- CodeLens namespace
local CODELENS_NS = vim.api.nvim_create_namespace("neoai_codelens")

-- CodeLens providers
local code_lens_providers = {
    {
        name = "explain",
        title = "🤖 Explain this code",
        action = M._explain_code,
        priority = 100,
    },
    {
        name = "refactor",
        title = "🔧 Refactor this code",
        action = M._refactor_code,
        priority = 90,
    },
    {
        name = "optimize",
        title = "⚡ Optimize this code",
        action = M._optimize_code,
        priority = 80,
    },
    {
        name = "test",
        title = "🧪 Generate tests",
        action = M._generate_tests,
        priority = 70,
    },
    {
        name = "document",
        title = "📝 Add documentation",
        action = M._add_documentation,
        priority = 60,
    },
}

-- Setup CodeLens
function M.setup()
    -- Create autocommand group
    local augroup = vim.api.nvim_create_augroup("NeoaiCodeLens", { clear = true })
    
    -- Update CodeLens on buffer changes
    vim.api.nvim_create_autocmd({
        "BufWritePost",
        "TextChanged",
        "TextChangedI",
        "BufEnter",
    }, {
        group = augroup,
        callback = M.update_codelens,
        desc = "NeoAI: Update CodeLens",
    })
    
    -- Clear CodeLens on buffer leave
    vim.api.nvim_create_autocmd("BufLeave", {
        group = augroup,
        callback = M.clear_codelens,
        desc = "NeoAI: Clear CodeLens",
    })
    
    -- Setup keymap for CodeLens action
    vim.keymap.set("n", "<leader>cl", M._run_codelens_at_cursor, {
        desc = "NeoAI: Run CodeLens at cursor",
        noremap = true,
        silent = true,
    })
end

-- Update CodeLens for current buffer
function M.update_codelens()
    local bufnr = vim.api.nvim_get_current_buf()
    local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
    
    -- Skip if CodeLens is disabled for this filetype
    if not M._is_enabled_for_filetype(ft) then
        return
    end
    
    M.clear_codelens()
    
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local codelens_data = {}
    
    -- Generate CodeLens for each line
    for line_num, line in ipairs(lines) do
        local line_codelens = M._generate_codelens_for_line(bufnr, line_num, line)
        if line_codelens and #line_codelens > 0 then
            codelens_data[line_num - 1] = line_codelens
        end
    end
    
    -- Set CodeLens
    if vim.lsp.codelens then
        vim.lsp.codelens.set(codelens_data, bufnr, CODELENS_NS)
    end
    
    -- Display CodeLens
    if vim.fn.has("nvim-0.6.0") == 1 and vim.lsp.codelens then
        vim.lsp.codelens.display(bufnr, CODELENS_NS)
    end
end

-- Clear CodeLens for current buffer
function M.clear_codelens()
    local bufnr = vim.api.nvim_get_current_buf()
    if vim.lsp.codelens then
        vim.lsp.codelens.clear(bufnr, CODELENS_NS)
    end
end

-- Generate CodeLens for a specific line
function M._generate_codelens_for_line(bufnr, line_num, line)
    local codelens = {}
    local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
    
    -- Skip empty lines and comments
    if vim.trim(line) == "" or M._is_comment_line(line, ft) then
        return {}
    end
    
    -- Generate CodeLens based on line content
    for _, provider in ipairs(code_lens_providers) do
        if M._should_show_codelens(provider.name, line, ft) then
            table.insert(codelens, {
                range = {
                    start = { line = line_num - 1, character = 0 },
                    ["end"] = { line = line_num - 1, character = #line },
                },
                command = {
                    title = provider.title,
                    command = "neoai.codelens.action",
                    arguments = { provider.name, line_num, line },
                },
            })
        end
    end
    
    return codelens
end

-- Check if CodeLens is enabled for filetype
function M._is_enabled_for_filetype(ft)
    local disabled_filetypes = {
        "terminal",
        "prompt",
        "NvimTree",
        "neoai-chat",
        "neoai-completion",
    }
    
    for _, disabled in ipairs(disabled_filetypes) do
        if ft == disabled then
            return false
        end
    end
    
    return true
end

-- Check if line is a comment
function M._is_comment_line(line, ft)
    local comment_patterns = {
        lua = { "^%s*%-%-" },
        python = { "^%s*#" },
        javascript = { "^%s*//", "^%s*/%*" },
        typescript = { "^%s*//", "^%s*/%*" },
        rust = { "^%s*//", "^%s*/%*" },
        go = { "^%s*//", "^%s*/%*" },
        c = { "^%s*//", "^%s*/%*" },
        cpp = { "^%s*//", "^%s*/%*" },
        java = { "^%s*//", "^%s*/%*" },
    }
    
    local patterns = comment_patterns[ft] or {}
    for _, pattern in ipairs(patterns) do
        if line:match(pattern) then
            return true
        end
    end
    
    return false
end

-- Check if CodeLens should be shown
function M._should_show_codelens(provider_name, line, ft)
    -- Context-specific CodeLens
    if provider_name == "test" then
        -- Show for functions and classes
        return line:match("function") or line:match("def ") or line:match("class ")
    elseif provider_name == "document" then
        -- Show for functions, classes, and complex lines
        return line:match("function") or line:match("def ") or line:match("class ") or #line > 50
    elseif provider_name == "refactor" then
        -- Show for complex lines
        return #line > 30 and (line:match("if") or line:match("for") or line:match("while"))
    elseif provider_name == "optimize" then
        -- Show for loops and performance-critical code
        return line:match("for") or line:match("while") or line:match("map") or line:match("filter")
    end
    
    -- Default: show for all non-empty lines
    return vim.trim(line) ~= ""
end

-- Run CodeLens at cursor
function M._run_codelens_at_cursor()
    local bufnr = vim.api.nvim_get_current_buf()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line_num = cursor[1]
    
    -- Get CodeLens at cursor position
    if not vim.lsp.codelens then
        vim.notify("NeoAI: CodeLens not available", vim.log.levels.WARN)
        return
    end
    
    local codelens = vim.lsp.codelens.get(bufnr)
    if not codelens then
        vim.notify("NeoAI: No CodeLens at cursor position", vim.log.levels.WARN)
        return
    end
    
    -- Find CodeLens at current line
    for _, lens in ipairs(codelens) do
        if lens.range.start.line == line_num - 1 then
            -- Execute the first CodeLens on this line
            if lens.command then
                vim.lsp.buf.execute_command(lens.command)
                return
            end
        end
    end
    
    vim.notify("NeoAI: No CodeLens at cursor position", vim.log.levels.WARN)
end

-- CodeLens actions
function M._explain_code(args)
    local provider_name, line_num, line = unpack(args)
    local chat = require("neoai.chat")
    
    -- Open chat with explanation request
    chat.open()
    vim.defer_fn(function()
        local prompt = string.format("Explain this line of code:\n\n```%s\n%s\n```", 
            vim.api.nvim_buf_get_option(0, "filetype"), line)
        chat.send_message(prompt)
    end, 500)
end

function M._refactor_code(args)
    local provider_name, line_num, line = unpack(args)
    local chat = require("neoai.chat")
    
    -- Open chat with refactoring request
    chat.open()
    vim.defer_fn(function()
        local prompt = string.format("Refactor this code to make it more readable and maintainable:\n\n```%s\n%s\n```", 
            vim.api.nvim_buf_get_option(0, "filetype"), line)
        chat.send_message(prompt)
    end, 500)
end

function M._optimize_code(args)
    local provider_name, line_num, line = unpack(args)
    local chat = require("neoai.chat")
    
    -- Open chat with optimization request
    chat.open()
    vim.defer_fn(function()
        local prompt = string.format("Optimize this code for better performance:\n\n```%s\n%s\n```", 
            vim.api.nvim_buf_get_option(0, "filetype"), line)
        chat.send_message(prompt)
    end, 500)
end

function M._generate_tests(args)
    local provider_name, line_num, line = unpack(args)
    local chat = require("neoai.chat")
    
    -- Get surrounding context for better test generation
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local context_start = math.max(1, line_num - 10)
    local context_end = math.min(#lines, line_num + 10)
    local context = table.concat(vim.list_slice(lines, context_start, context_end), "\n")
    
    -- Open chat with test generation request
    chat.open()
    vim.defer_fn(function()
        local prompt = string.format("Generate unit tests for this code:\n\n```%s\n%s\n```", 
            vim.api.nvim_buf_get_option(0, "filetype"), context)
        chat.send_message(prompt)
    end, 500)
end

function M._add_documentation(args)
    local provider_name, line_num, line = unpack(args)
    local chat = require("neoai.chat")
    
    -- Open chat with documentation request
    chat.open()
    vim.defer_fn(function()
        local prompt = string.format("Add comprehensive documentation for this code:\n\n```%s\n%s\n```", 
            vim.api.nvim_buf_get_option(0, "filetype"), line)
        chat.send_message(prompt)
    end, 500)
end

-- Register CodeLens command
vim.api.nvim_create_user_command("NeoaiCodeLensAction", function(opts)
    local args = opts.fargs
    if #args >= 3 then
        local provider_name = args[1]
        local line_num = tonumber(args[2])
        local line = table.concat(args, " ", 3)
        
        -- Find and execute the provider action
        for _, provider in ipairs(code_lens_providers) do
            if provider.name == provider_name then
                provider.action({provider_name, line_num, line})
                return
            end
        end
    end
end, {
    nargs = "*",
    desc = "NeoAI: Execute CodeLens action",
})

return M
