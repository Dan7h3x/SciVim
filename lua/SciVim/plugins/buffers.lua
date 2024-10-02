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
			{ "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
			{ "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
			{ "[B", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer prev" },
			{ "]B", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer next" },
		},
		opts = {
			options = {
				mode = "buffers",
				themable = true,
				numbers = "ordinal",
				close_command = "bdelete! %d",
				indicator = {
					icon = "▕",
					style = "icon",
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
						highlight = "SciVimTab",
						separator = true,
					},
					{
						filetype = "alpha",
						text = " ",
						text_align = "center",
						highlight = "SciVimTab",
					},
					{
						filetype = "termim",
						text = "  Terminal",
						text_align = "center",
						separator = true,
					},
					{
						filetype = "Outline",
						text = " Symbols",
						highlight = "SciVimTab",
						text_align = "center",
						separator = true,
					},
					{
						filetype = "undotree",
						text = "  Undo",
						highlight = "SciVimTab",
						text_align = "center",
						separator = true,
					},
					{
						filetype = "dap-repl",
						text = "  Debugging",
						highlight = "SciVimTab",
						text_align = "center",
						separator = true,
					},
				},
				color_icons = true,

				separator_style = "slant",
				hover = {
					enabled = true,
					delay = 200,
					reveal = { "close" },
				},
			},
		},
	},
}
