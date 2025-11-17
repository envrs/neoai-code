local M = {}
local api = vim.api
local chat = require("neoai.chat")
local config = require("neoai.config")
local status = require("neoai.status")
local neoai_binary = require("neoai.binary")
-- local ts_utls = require("nvim-treesitter.ts_utils")

function M.setup()
	if not config.is_enterprise() then
		api.nvim_create_user_command("NeoaiHub", function()
			neoai_binary:request({ Configuration = { quiet = false } }, function() end)
		end, {})

		api.nvim_create_user_command("NeoaiHubUrl", function()
			neoai_binary:request({ Configuration = { quiet = true } }, function(response)
				print(response.message)
			end)
		end, {})

		api.nvim_create_user_command("NeoaiWhoAmI", function()
			neoai_binary:request({ State = { quiet = false } }, function(response)
				print(response.user_name)
			end)
		end, {})
	else
		api.nvim_create_user_command("NeoaiWhoAmI", function()
			neoai_binary:request({ UserInfo = { quiet = false } }, function(response)
				print(response.email)
			end)
		end, {})
	end

	api.nvim_create_user_command("NeoaiLoginWithAuthToken", function()
		neoai_binary:request({ LoginWithCustomTokenUrl = { dummy = true } }, function(url)
			vim.ui.input({
				prompt = string.format("Get your token from: %s\nPaste it here: ", url),
			}, function(custom_token)
				neoai_binary:request({
					LoginWithCustomToken = { custom_token = custom_token },
				}, function(response)
					if response.is_success then
						vim.notify("Logged in successfully")
					else
						vim.notify("Sign in failed", vim.log.levels.WARN)
					end
				end)
			end)
		end)
	end, {})

	api.nvim_create_user_command("NeoaiLogin", function()
		neoai_binary:request({ Login = { dummy = true } }, function() end)
	end, {})

	api.nvim_create_user_command("NeoaiLogout", function()
		neoai_binary:request({ Logout = { dummy = true } }, function() end)
	end, {})

	api.nvim_create_user_command("NeoaiEnable", status.enable_neoai, {})
	api.nvim_create_user_command("NeoaiDisable", status.disable_neoai, {})
	api.nvim_create_user_command("NeoaiToggle", status.toggle_neoai, {})
	api.nvim_create_user_command("NeoaiStatus", function()
		print(status.status())
	end, {})
end

return M