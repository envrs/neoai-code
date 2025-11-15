local consts = require("neoai.consts")
local config = require("neoai.config")
local state = require("neoai.state")
local features = require("neoai.features")
local utils = require("neoai.utils")

local M = {}

-- LSP client registry
local lsp_clients = {}

-- Setup LSP integration
function M.setup()
    if not features.is_enabled("lsp_integration") then
        return
    end
    
    vim.notify("NeoAI: LSP integration enabled", vim.log.levels.DEBUG)
end

-- Called when LSP attaches to a buffer
function M.on_attach(client_data, bufnr)
    if not features.is_enabled("lsp_integration") then
        return
    end
    
    local client = vim.lsp.get_client_by_id(client_data.client_id)
    if not client then
        return
    end
    
    -- Register client
    lsp_clients[bufnr] = lsp_clients[bufnr] or {}
    table.insert(lsp_clients[bufnr], client)
    
    -- Setup NeoAI LSP features for this buffer
    M.setup_buffer_features(client, bufnr)
    
    vim.notify("NeoAI: LSP client attached: " .. client.name, vim.log.levels.DEBUG)
end

-- Called when LSP detaches from a buffer
function M.on_detach(client_data, bufnr)
    if lsp_clients[bufnr] then
        lsp_clients[bufnr] = nil
        vim.notify("NeoAI: LSP client detached", vim.log.levels.DEBUG)
    end
end

-- Setup buffer-specific LSP features
function M.setup_buffer_features(client, bufnr)
    -- Add NeoAI commands to buffer
    vim.api.nvim_buf_create_user_command(bufnr, "NeoaiLspInfo", function()
        M.show_lsp_info(bufnr)
    end, { desc = "Show NeoAI LSP information" })
    
    vim.api.nvim_buf_create_user_command(bufnr, "NeoaiLspSymbols", function()
        M.get_document_symbols(bufnr)
    end, { desc = "Get LSP document symbols" })
    
    -- Setup keymaps for LSP integration
    local opts = { buffer = bufnr, silent = true }
    vim.keymap.set("n", "<leader>ai", M.show_lsp_info, opts)
    vim.keymap.set("n", "<leader>as", M.get_document_symbols, opts)
end

-- Get LSP information
function M.show_lsp_info(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local clients = lsp_clients[bufnr] or {}
    
    if #clients == 0 then
        vim.notify("NeoAI: No LSP clients attached", vim.log.levels.INFO)
        return
    end
    
    local info = "NeoAI LSP Information:\n\n"
    
    for i, client in ipairs(clients) do
        info = info .. string.format([[
Client %d:
- Name: %s
- ID: %d
- Version: %s
- Capabilities: %s
]], 
            i,
            client.name,
            client.id,
            client.version or "Unknown",
            vim.inspect(client.server_capabilities or {})
        )
    end
    
    vim.notify(info, vim.log.levels.INFO)
end

-- Get document symbols from LSP
function M.get_document_symbols(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local clients = lsp_clients[bufnr] or {}
    
    if #clients == 0 then
        vim.notify("NeoAI: No LSP clients attached", vim.log.levels.WARN)
        return
    end
    
    -- Find a client that supports document symbols
    local client = nil
    for _, c in ipairs(clients) do
        if c.server_capabilities and c.server_capabilities.documentSymbolProvider then
            client = c
            break
        end
    end
    
    if not client then
        vim.notify("NeoAI: No LSP client supports document symbols", vim.log.levels.WARN)
        return
    end
    
    -- Request document symbols
    local params = { textDocument = vim.lsp.util.make_text_document_params() }
    client.request("textDocument/documentSymbol", params, function(err, result)
        if err then
            vim.notify("NeoAI LSP Error: " .. err.message, vim.log.levels.ERROR)
            return
        end
        
        if not result or #result == 0 then
            vim.notify("NeoAI: No symbols found", vim.log.levels.INFO)
            return
        end
        
        M.display_symbols(result)
    end, bufnr)
end

-- Display symbols in a floating window
function M.display_symbols(symbols)
    local lines = { "Document Symbols:", "" }
    
    local function add_symbol(symbol, indent)
        local kind = vim.lsp.protocol.SymbolKind[symbol.kind] or "Unknown"
        local line = string.rep("  ", indent) .. "● " .. symbol.name .. " (" .. kind .. ")"
        table.insert(lines, line)
        
        if symbol.children then
            for _, child in ipairs(symbol.children) do
                add_symbol(child, indent + 1)
            end
        end
    end
    
    for _, symbol in ipairs(symbols) do
        add_symbol(symbol, 0)
    end
    
    -- Create floating window
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "cursor",
        width = 80,
        height = math.min(#lines, 20),
        col = 0,
        row = 1,
        border = "single",
        style = "minimal",
    })
    
    -- Setup window keymaps
    vim.keymap.set("n", "q", function()
        vim.api.nvim_win_close(win, true)
    end, { buffer = buf, silent = true })
    
    vim.keymap.set("n", "<Esc>", function()
        vim.api.nvim_win_close(win, true)
    end, { buffer = buf, silent = true })
end

-- Get workspace context using LSP
function M.get_lsp_context(bufnr, max_symbols)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    max_symbols = max_symbols or 50
    
    local clients = lsp_clients[bufnr] or {}
    if #clients == 0 then
        return nil
    end
    
    -- Find a client that supports document symbols
    local client = nil
    for _, c in ipairs(clients) do
        if c.server_capabilities and c.server_capabilities.documentSymbolProvider then
            client = c
            break
        end
    end
    
    if not client then
        return nil
    end
    
    -- Request document symbols synchronously for context
    local params = { textDocument = vim.lsp.util.make_text_document_params() }
    local result = client.request_sync("textDocument/documentSymbol", params, 1000, bufnr)
    
    if not result or not result.result then
        return nil
    end
    
    local symbols = result.result
    local context = {
        symbols = {},
        functions = {},
        variables = {},
        classes = {},
    }
    
    local function process_symbol(symbol)
        local info = {
            name = symbol.name,
            kind = vim.lsp.protocol.SymbolKind[symbol.kind] or "Unknown",
            range = symbol.range,
            selection_range = symbol.selection_range,
        }
        
        table.insert(context.symbols, info)
        
        -- Categorize symbols
        if symbol.kind == 12 then -- Function
            table.insert(context.functions, info)
        elseif symbol.kind == 13 then -- Variable
            table.insert(context.variables, info)
        elseif symbol.kind == 5 then -- Class
            table.insert(context.classes, info)
        end
        
        -- Process children
        if symbol.children and #context.symbols < max_symbols then
            for _, child in ipairs(symbol.children) do
                process_symbol(child)
            end
        end
    end
    
    for _, symbol in ipairs(symbols) do
        if #context.symbols >= max_symbols then
            break
        end
        process_symbol(symbol)
    end
    
    return context
end

-- Get code actions using LSP
function M.get_code_actions(bufnr, range)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local clients = lsp_clients[bufnr] or {}
    
    if #clients == 0 then
        return {}
    end
    
    -- Find a client that supports code actions
    local client = nil
    for _, c in ipairs(clients) do
        if c.server_capabilities and c.server_capabilities.codeActionProvider then
            client = c
            break
        end
    end
    
    if not client then
        return {}
    end
    
    local params = vim.lsp.util.make_range_params()
    if range then
        params.range = range
    end
    
    local result = client.request_sync("textDocument/codeAction", params, 1000, bufnr)
    
    if not result or not result.result then
        return {}
    end
    
    return result.result
end

-- Get hover information using LSP
function M.get_hover_info(bufnr, position)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    position = position or utils.get_cursor()
    
    local clients = lsp_clients[bufnr] or {}
    
    if #clients == 0 then
        return nil
    end
    
    -- Find a client that supports hover
    local client = nil
    for _, c in ipairs(clients) do
        if c.server_capabilities and c.server_capabilities.hoverProvider then
            client = c
            break
        end
    end
    
    if not client then
        return nil
    end
    
    local params = {
        textDocument = vim.lsp.util.make_text_document_params(),
        position = { line = position[1] - 1, character = position[2] },
    }
    
    local result = client.request_sync("textDocument/hover", params, 1000, bufnr)
    
    if not result or not result.result or not result.result.contents then
        return nil
    end
    
    return result.result
end

-- Get all attached clients
function M.get_clients(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    return lsp_clients[bufnr] or {}
end

-- Check if buffer has LSP support
function M.has_lsp(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local clients = lsp_clients[bufnr] or {}
    return #clients > 0
end

return M