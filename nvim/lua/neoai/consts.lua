local api = vim.api

return {
	plugin_version = "1.7.0",
	min_nvim_version = "0.7.1",
	max_chars = 3000,
	neoai_hl_group = "NeoaiSuggestion",
	neoai_codelens_hl_group = "NeoaiCodeLens",
	neoai_namespace = api.nvim_create_namespace("neoai"),
	neoai_codelens_namespace = api.nvim_create_namespace("neoai_codelens"),
	valid_end_of_line_regex = vim.regex("^\\s*[)}\\]\"'`]*\\s*[:{;,]*\\s*$"),
}