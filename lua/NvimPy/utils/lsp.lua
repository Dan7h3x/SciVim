---@class NvimPy.utils.lsp
local M = {}

---@param from string
---@param to string
---@param rename? fun()
function M.on_rename(from, to, rename)
	local changes = { files = { {
		oldUri = vim.uri_from_fname(from),
		newUri = vim.uri_from_fname(to),
	} } }

	local clients = M.get_clients()
	for _, client in ipairs(clients) do
		if client.supports_method("workspace/willRenameFiles") then
			local resp = client.request_sync("workspace/willRenameFiles", changes, 1000, 0)
			if resp and resp.result ~= nil then
				vim.lsp.util.apply_workspace_edit(resp.result, client.offset_encoding)
			end
		end
	end

	if rename then
		rename()
	end

	for _, client in ipairs(clients) do
		if client.supports_method("workspace/didRenameFiles") then
			client.notify("workspace/didRenameFiles", changes)
		end
	end
end

return M
