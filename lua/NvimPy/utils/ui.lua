---@class NvimPy.utils.ui
local M = {}

local nu = { number = true, relativenumber = true }
function M.number()
	if vim.opt_local.number:get() or vim.opt_local.relativenumber:get() then
		nu = { number = vim.opt_local.number:get(), relativenumber = vim.opt_local.relativenumber:get() }
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
		require("lazy.core.util").warn("Disabled line numbers", { title = "Option" })
	else
		vim.opt_local.number = nu.number
		vim.opt_local.relativenumber = nu.relativenumber
		require("lazy.core.util").info("Enabled line numbers", { title = "Option" })
	end
end

return M
