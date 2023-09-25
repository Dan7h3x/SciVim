local null_ls = require("null-ls")
vim.lsp.handlers["null-ls/formatting/textidote"] = function(err, method, result, client_id, bufnr, config)
	if err ~= nil or result == nil then
		return
	end

	for _, diagnostic in ipairs(result) do
		local range = diagnostic.range
		local message = diagnostic.message
		local severity = diagnostic.severity
		local nvim_severity = {
			hint = vim.lsp.protocol.DiagnosticSeverity.Hint,
			info = vim.lsp.protocol.DiagnosticSeverity.Information,
			warning = vim.lsp.protocol.DiagnosticSeverity.Warning,
			error = vim.lsp.protocol.DiagnosticSeverity.Error,
		}
		vim.lsp.diagnostic.set(
			bufnr,
			client_id,
			{
				{
					range = {
						["start"] = {
							line = range.start.line + 1,
							character = range.start.character,
						},
						["end"] = {
							line = range["end"].line + 1,
							character = range["end"].character,
						},
					},
					severity = nvim_severity[severity],
					message = message,
				},
			},
			{}
		)
	end
end
