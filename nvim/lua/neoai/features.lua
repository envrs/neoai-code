local M = {}
local neoai_binary = require("neoai.binary")

function M.if_feature_enabled(features, run_if_enabled)
	neoai_binary:request({ Features = { dummy = true } }, function(response)
		if not response or not response.enabled_features then return end
		for _, feature in ipairs(features) do
			if vim.tbl_contains(response.enabled_features, feature) then
				run_if_enabled()
				return
			end
		end
	end)
end

return M