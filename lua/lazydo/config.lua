---@class LazyDoConfig
---@field theme table UI theme configuration
---@field keymaps table Keymap configuration
---@field icons table Icon configuration
---@field date_format string Date format string
---@field storage_path? string Custom storage path
local Config = {}

---Default configuration
local defaults = {
	theme = {
		border = "rounded",
		colors = {
			header = { fg = "#7aa2f7", bold = true },
			title = { fg = "#7dcfff", bold = true },
			task = {
				pending = { fg = "#a9b1d6" },
				done = { fg = "#56ff89", italic = true },
				overdue = { fg = "#f7768e", bold = true },
				blocked = { fg = "#f7768e", italic = true },
				in_progress = { fg = "#7aa2f7", bold = true },
				info = { fg = "#78ac99", italic = true },
			},
			priority = {
				high = { fg = "#f7768e", bold = true },
				medium = { fg = "#e0af68" },
				low = { fg = "#9ece6a" },
				urgent = { fg = "#db4b4b", bold = true, undercurl = true },
			},
			-- In config.lua, update the notes colors:
			notes = {
				header = {
					fg = "#7dcfff",
					bold = true,
				},
				body = {
					fg = "#d9a637",
					italic = true,
				},
				border = {
					fg = "#3b4261",
				},
				icon = {
					fg = "#fdcfff",
					bold = true,
				},
			},
			due_date = {
				fg = "#bb9af7",
				near = { fg = "#e0af68", bold = true },
				overdue = { fg = "#f7768e", undercurl = true },
			},
			progress = {
				complete = { fg = "#9ece6a" },
				partial = { fg = "#e0af68" },
				none = { fg = "#f7768e" },
			},
			separator = {
				fg = "#3b4261",
				vertical = { fg = "#3b4261" },
				horizontal = { fg = "#3b4261" },
			},
			help = {
				fg = "#c0caf5",
				key = { fg = "#7dcfff", bold = true },
				text = { fg = "#c0caf5", italic = true },
			},
			fold = {
				expanded = { fg = "#7aa2f7", bold = true },
				collapsed = { fg = "#7aa2f7" },
			},
			indent = {
				line = { fg = "#3b4261" },
				connector = { fg = "#3bf2f1" },
				indicator = { fg = "#fb42f1", bold = true },
			},
			search = {
				match = { fg = "#c0caf5", bg = "#445588", bold = true },
			},
			selection = { fg = "#c0caf5", bg = "#283457", bold = true },
			cursor = { fg = "#c0caf5", bg = "#364a82", bold = true },
		},
		progress_bar = {
			width = 15,
			filled = "█",
			empty = "░",
			enabled = true,
			style = "modern", -- "classic", "modern", "minimal"
		},
		indent = {
			marker = "│",
			connector = "├─",
			last_connector = "└─",
		},
	},

	icons = {
		task_pending = "",
		task_done = "",
		priority = {
			low = "󰘄",
			medium = "󰁭",
			high = "󰘃",
			urgent = "󰀦",
		},
		created = "󰃰",
		updated = "",
		note = "",
		due_date = "",
		recurring = {
			daily = "",
			weekly = "",
			monthly = "",
		},
		metadata = "󰂵",
		important = "",
	},
	date_format = "%Y-%m-%d",
	storage_path = nil, -- Uses default if not specified
	features = {
		task_info = {
			enabled = true,
		},

		folding = {
			enabled = true,
			default_folded = false,
			icons = {
				folded = "▶",
				unfolded = "▼",
			},
		},
		tags = {
			enabled = true,
			colors = {
				fg = "#7aa2f7",
			},
			prefix = "󰓹 ",
		},
		-- attachments = {
		-- 	enabled = true,
		-- 	storage = "local", -- "local" or "git"
		-- 	path = "~/.local/share/lazydo/attachments",
		-- 	max_size = 10 * 1024 * 1024, -- 10MB
		-- 	allowed_types = {
		-- 		"image/*",
		-- 		"text/*",
		-- 		"application/pdf",
		-- 	},
		-- },

		-- templates = {
		-- 	enabled = true,
		-- 	path = "~/.config/lazydo/templates",
		-- 	default_template = "basic",
		-- },
		relations = {
			enabled = true,
			types = {
				"blocks",
				"depends_on",
				"related_to",
				"duplicates",
			},
		},

		metadata = {
			enabled = true,
			display = true,
			colors = {
				key = { fg = "#f0caf5", bg = "#bb9af7", bold = true },
				value = { fg = "#c0faf5", bg = "#7dcfff" },
				section = { fg = "#00caf5", bg = "#bb9af7", bold = true, italic = true },
			},
		},
		progress = {
			enabled = true,
			style = "modern", -- "classic", "modern", "minimal"
			colors = {
				low = "#f7768e",
				medium = "#e0af68",
				high = "#9ece6a",
			},
		},
		search = {
			live_update = true,
			highlight_matches = true,
			case_sensitive = false,
			fuzzy = true,
			include_notes = true,
			include_tags = true,
			include_metadata = true,
			live_preview = true,
		},
	},
	layout = {
		width = 0.7, -- Percentage of screen width
		height = 0.8, -- Percentage of screen height
		spacing = 1, -- Lines between tasks
		task_padding = 1, -- Padding around task content
		metadata_position = "bottom", -- "bottom" or "right"
	},
}
---Setup configuration
---@param opts? table User configuration
---@return LazyDoConfig
function Config.setup(opts)
	opts = opts or {}
	return vim.tbl_deep_extend("force", defaults, opts)
end

return Config
