require("barbecue").setup({
	attach_navic = true, -- prevent barbecue from automatically attaching nvim-navic
	modifiers = {
		dirname = ":~:.",
		basename = "",
	},
	exclude_filetypes = { "neo-tree", "nvterm" },
	show_dirname = true,
	show_basename = true,
	modified = function(bufnr)
		return vim.bo[bufnr].modified
	end,
	show_navic = true,
	theme = "nightfly",
	symbols = {
		separator = "|",
	},
})

require("lspconfig")[server].setup({
	-- ...

	on_attach = function(client, bufnr)
		-- ...

		if client.server_capabilities["documentSymbolProvider"] then
			require("nvim-navic").attach(client, bufnr)
		end

		-- ...
	end,

	-- ...
})
