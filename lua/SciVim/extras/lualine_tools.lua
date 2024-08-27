--[[
-- MyTools for lualine
--]]
local M = {}

function M.lsp_servers_new()
	local clients = vim.lsp.get_clients()
	local servers = {}
	for _, client in ipairs(clients) do
		table.insert(servers, client.name)
	end
	local uniqe_servers = {}
	for _, name in ipairs(servers) do
		if not vim.tbl_contains(uniqe_servers, name) then
			table.insert(uniqe_servers, name)
		end
	end

	if next(clients) == nil then
		return "OFF"
	else
		return table.concat(uniqe_servers, ",")
	end
end

return M
