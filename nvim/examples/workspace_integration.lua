-- Workspace Integration Example
-- This demonstrates how to use NeoAI's workspace features

require("neoai").setup({
  api_key = "your-api-key-here",
  features = {
    workspace_integration = true,
    lsp_integration = true,
  },
})

-- Get workspace context
local function show_workspace_context()
  local neoai = require("neoai")
  local context = neoai.get_context({
    max_files = 50,        -- Maximum files to include
    max_content = 10000,   -- Maximum content size per file
  })
  
  print("Workspace files found: " .. #context.files)
  for _, file in ipairs(context.files) do
    print("  - " .. file.path .. " (" .. file.size .. " bytes)")
  end
end

-- Find specific files in workspace
local function find_files(pattern, file_type)
  local workspace = require("neoai.workspace")
  local files = workspace.find_files(pattern, file_type)
  
  print("Found " .. #files .. " files matching '" .. pattern .. "'")
  for _, file in ipairs(files) do
    print("  - " .. file.path)
  end
end

-- Get file information
local function get_file_info(path)
  local workspace = require("neoai.workspace")
  local file = workspace.get_file(path)
  
  if file then
    print("File: " .. file.path)
    print("  Size: " .. file.size .. " bytes")
    print("  Modified: " .. file.modified)
    print("  Type: " .. file.type)
  else
    print("File not found: " .. path)
  end
end

-- Get workspace statistics
local function show_workspace_stats()
  local workspace = require("neoai.workspace")
  local stats = workspace.get_statistics()
  
  print("Workspace Statistics:")
  print("  Total files: " .. stats.total_files)
  print("  Total size: " .. stats.total_size .. " bytes")
  print("  Languages: " .. vim.inspect(stats.languages))
end

-- Example usage with keymaps
vim.keymap.set("n", "<leader>ws", show_workspace_context, 
  { desc = "NeoAI: Show Workspace Context" })

vim.keymap.set("n", "<leader>wf", function()
  vim.ui.input({ prompt = "File pattern: " }, function(pattern)
    if pattern then
      find_files(pattern, nil)
    end
  end)
end, { desc = "NeoAI: Find Files" })

vim.keymap.set("n", "<leader>wi", function()
  vim.ui.input({ prompt = "File path: " }, function(path)
    if path then
      get_file_info(path)
    end
  end)
end, { desc = "NeoAI: File Info" })

vim.keymap.set("n", "<leader>wstats", show_workspace_stats,
  { desc = "NeoAI: Workspace Statistics" })

-- Auto-update workspace on directory changes
local function setup_workspace_auto_update()
  local workspace = require("neoai.workspace")
  local timer = vim.loop.new_timer()
  
  timer:start(5000, 30000, vim.schedule_wrap(function()
    workspace.update_workspace_files()
  end))
end

-- Initialize workspace
setup_workspace_auto_update()
