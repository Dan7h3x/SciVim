local bufferline = require("bufferline")
local groups = require("bufferline.groups")
bufferline.setup({
	options = {
		mode = "buffers", -- set to "tabs" to only show tabpages instead
		themable = false, -- allows highlight groups to be overriden i.e. sets highlights as default
		theme = "tokyonight",
		numbers = function(opts)
			return string.format("%s.%s", opts.raise(opts.id), opts.lower(opts.ordinal))
		end,
		close_command = "bdelete! %d", -- can be a string | function, | false see "Mouse actions"
		right_mouse_command = "bdelete! %d", -- can be a string | function | false, see "Mouse actions"
		left_mouse_command = "buffer %d", -- can be a string | function, | false see "Mouse actions"
		middle_mouse_command = nil, -- can be a string | function, | false see "Mouse actions"
		indicator = {
			icon = "▎", -- this should be omitted if indicator style is not 'icon'
			style = "underline",
		},
		buffer_close_icon = "",
		modified_icon = "●",
		close_icon = "",
		left_trunc_marker = "",
		right_trunc_marker = "",
		--- name_formatter can be used to change the buffer's label in the bufferline.
		--- Please note some names can/will break the
		--- bufferline so use this at your discretion knowing that it has
		--- some limitations that will *NOT* be fixed.
		max_name_length = 18,
		max_prefix_length = 15, -- prefix used when a buffer is de-duplicated
		truncate_names = true, -- whether or not tab names should be truncated
		tab_size = 18,
		diagnostics = "nvim_lsp",
		diagnostics_update_in_insert = false,
		-- The diagnostics indicator can be set to nil to keep the buffer name highlight but delete the highlighting
		-- NOTE: this will be called a lot so don't do any heavy processing here

		offsets = {
			{
				filetype = "neo-tree",
				text = " Files",
				text_align = "center",
				separator = true,
			},
			{
				filetype = "terminal",
				text = "﮸ Terminal",
				text_align = "center",
				separator = true,
			},
			{
				filetype = "Outline",
				text = " Symbols",
				text_align = "center",
				separator = true,
			},
			{
				filetype = "undotree",
				text = " UndoTree",
				text_align = "center",
				separator = true,
			},
			{
				filetype = "alpha",
				text = " NvimPy",
				text_align = "center",
				separator = true,
			},
			{
				filetype = "dapui*",
				text = "ﭯ Debug",
				text_align = "center",
				separator = true,
			},
		},
		color_icons = true, -- whether or not to add the filetype icon highlights
		show_buffer_icons = true, -- disable filetype icons for buffers
		show_buffer_close_icons = true,
		show_close_icon = true,
		show_tab_indicators = true,
		show_duplicate_prefix = true, -- whether to show duplicate buffer prefix
		persist_buffer_sort = true, -- whether or not custom sorted buffers should persist
		-- can also be a table containing 2 custom separators
		-- [focused and unfocused]. eg: { '|', '|' }
		separator_style = "padded_slant",
		highlights = {
			buffer_selected = {
				fg = "#fafafa",
				bg = "#faaa3a",
				bold = true,
				italic = true,
			},
		},
		enforce_regular_tabs = false,
		always_show_bufferline = off,
		hover = {
			enabled = true,
			delay = 200,
			reveal = { "close" },
		},
		sort_by = "insert_after_current",
		groups = {
			items = {
				{ name = "G 1", ... },
				groups.builtin.ungrouped,
				{ name = "G 2", ... },
			},
		},
	},
})
