return {
	{
		"akinsho/bufferline.nvim",
		event = "VeryLazy",
		keys = {
			{ "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin" },
			{ "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
			{ "<leader>bo", "<Cmd>BufferLineCloseOthers<CR>", desc = "Delete Other Buffers" },
			{ "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to the Right" },
			{ "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete Buffers to the Left" },
			{ "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
			{ "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
			{ "[b", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer prev" },
			{ "]b", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer next" },
		},
		opts = {
			options = {
				mode = "buffers",
				themable = true,
				numbers = "ordinal",
				close_command = "bdelete! %d",
				indicator = {
					icon = "▕",
					style = "underline",
				},
				buffer_close_icon = "",
				modified_icon = " ",
				diagnostics = "nvim_lsp",
				diagnostics_indicator = function(count, level, diagnostics_dict, context)
					return "{" .. count .. "}"
				end,
				offsets = {
					{
						filetype = "neo-tree",
						text = "  Files",
						text_align = "center",
						highlight = "Tab",
						separator = true,
					},
					{
						filetype = "alpha",
						text = "󰂚 Dashboard",
						text_align = "center",
						highlight = "Tab",
					},
					{
						filetype = "neaterm",
						text = "  Terminal",
						text_align = "center",
						highlight = "Tab",
						separator = true,
					},
					{
						filetype = "Outline",
						text = " Symbols",
						highlight = "Tab",
						text_align = "center",
						separator = true,
					},
					{
						filetype = "undotree",
						text = "  Undo",
						highlight = "Tab",
						text_align = "center",
						separator = true,
					},
					{
						filetype = "dap-repl",
						text = "  Debugging",
						highlight = "Tab",
						text_align = "center",
						separator = true,
					},
				},
				color_icons = true,

				separator_style = "thin",
				hover = {
					enabled = true,
					delay = 200,
					reveal = { "close" },
				},
			},
		},
	},
}
