local M = {}
local config = {}

function M.set_config(o)
	config = vim.tbl_deep_extend("force", {
		disable_auto_comment = false,
		accept_keymap = "<Tab>",
		dismiss_keymap = "<C-]>",
		debounce_ms = 800,
		suggestion_color = { gui = "#808080", cterm = 244 },
		codelens_color = { gui = "#808080", cterm = 244 },
		codelens_enabled = true,
		exclude_filetypes = { "TelescopePrompt", "NvimTree" },
		log_file_path = nil,
		neoai_enterprise_host = nil,
		ignore_certificate_errors = false,
		workspace_folders = {
			paths = {},
			lsp = true,
			get_paths = nil,
		},
	}, o or {})
end

function M.get_config()
	return config
end

function M.is_enterprise()
	return config.neoai_enterprise_host ~= nil
end

function M.get(key)
	if not key then
		return config
	end
	
	-- Support dot notation for nested keys
	local keys = vim.split(key, ".", { plain = true })
	local value = config
	
	for _, k in ipairs(keys) do
		if type(value) == "table" then
			value = value[k]
		else
			return nil
		end
	end
	
	return value
end

function M.set(key, value)
	if not key then
		return
	end
	
	-- Support dot notation for nested keys
	local keys = vim.split(key, ".", { plain = true })
	local target = config
	
	-- Navigate to the parent of the target key
	for i = 1, #keys - 1 do
		local k = keys[i]
		if type(target) ~= "table" then
			return
		end
		if not target[k] then
			target[k] = {}
		end
		target = target[k]
	end
	
	-- Set the final value
	target[keys[#keys]] = value
end

return M