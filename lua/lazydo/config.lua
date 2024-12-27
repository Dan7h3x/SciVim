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
			header = { bg = "#1a1b26", fg = "#7aa2f7", bold = true },
			title = { bg = "#1a1b26", fg = "#7dcfff", bold = true },
			task = {
				pending = { bg = "#1a1b26", fg = "#a9b1d6" },
				done = { bg = "#1a1b26", fg = "#565f89", italic = true },
				overdue = { bg = "#1a1b26", fg = "#f7768e", bold = true },
				blocked = { bg = "#1a1b26", fg = "#f7768e", italic = true },
				in_progress = { bg = "#1a1b26", fg = "#7aa2f7", bold = true },
				info = { bg = "#1a1b26", fg = "#787c99", italic = true },
			},
			priority = {
				high = { fg = "#f7768e", bg = "#1a1b26", bold = true },
				medium = { fg = "#e0af68", bg = "#1a1b26" },
				low = { fg = "#9ece6a", bg = "#1a1b26" },
				urgent = { fg = "#db4b4b", bg = "#1a1b26", bold = true, undercurl = true },
			},
			-- In config.lua, update the notes colors:
			notes = {
				header = {
					fg = "#7dcfff",
					bg = "#1a1b26",
					bold = true,
				},
				body = {
					fg = "#c0caf5",
					bg = "#1a1b26",
					italic = true,
				},
				border = {
					fg = "#3b4261",
					bg = "#1a1b26",
				},
				icon = {
					fg = "#7dcfff",
					bg = "#1a1b26",
					bold = true,
				},
			},
			due_date = {
				bg = "#1a1b26",
				fg = "#bb9af7",
				near = { fg = "#e0af68", bg = "#1a1b26", bold = true },
				overdue = { fg = "#f7768e", bg = "#1a1b26", undercurl = true },
			},
			progress = {
				bar = {
					filled = { fg = "#7aa2f7", bg = "#1a1b26" },
					empty = { fg = "#3b4261", bg = "#1a1b26" },
					text = { fg = "#c0caf5", bg = "#1a1b26" },
				},
				complete = { fg = "#9ece6a", bg = "#1a1b26" },
				partial = { fg = "#e0af68", bg = "#1a1b26" },
				none = { fg = "#f7768e", bg = "#1a1b26" },
				border = { fg = "#7aa2f7", bg = "#1a1b26" },
			},
			separator = {
				fg = "#3b4261",
				bg = "#1a1b26",
				vertical = { fg = "#3b4261", bg = "#1a1b26" },
				horizontal = { fg = "#3b4261", bg = "#1a1b26" },
			},
			help = {
				fg = "#c0caf5",
				bg = "#1a1b26",
				key = { fg = "#7dcfff", bg = "#1a1b26", bold = true },
				text = { fg = "#c0caf5", bg = "#1a1b26", italic = true },
			},
			fold = {
				expanded = { fg = "#7aa2f7", bg = "#1a1b26", bold = true },
				collapsed = { fg = "#7aa2f7", bg = "#1a1b26" },
			},
			indent = {
				line = { fg = "#3b4261", bg = "#1a1b26" },
				connector = { fg = "#3b4261", bg = "#1a1b26" },
				indicator = { fg = "#3b4261", bg = "#1a1b26", bold = true },
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
			size = 2,
			marker = "│",
			connector = "├─",
			last_connector = "└─",
		},

		task_indicators = {
			enabled = true,
			icons = {
				has_notes = "📝",
				has_subtasks = "📑",
				has_attachments = "📎",
				is_recurring = "🔄",
				is_important = "⭐",
			},
		},
		completion_markers = {
			enabled = true,
			style = "modern", -- "classic", "modern", "minimal"
			icons = {
				done = "✓",
				pending = "○",
				in_progress = "◐",
				blocked = "✗",
			},
		},
	},
	keymaps = {
		toggle_status = "<CR>",
		delete_task = "d",
		edit_task = "e",
		add_note = "n",
		cycle_priority = "p",
		set_due_date = "D",
		add_subtask = "A",
		close = "q",
		help = "?",
		move_up = "K",
		move_down = "J",
		toggle_fold = "z",
		quick_add = "a",
		add_tag = "t",
		set_metadata = "m",
		search = "/",
		duplicate = "y",
		set_recurring = "r",
		export_markdown = "<leader>m",
		convert_to_subtask = "<leader>s",
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
		note = " ",
		due_date = " ",
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
			show_timestamps = true,
			show_progress = true,
		},
		notes = {
			enabled = true,
			max_width = 60,
			icons = {
				parent = "╭",
				child = "├",
			},
		},
		progress_bar = {
			enabled = true,
			style = "modern", -- modern/classic/minimal
			width = 20,
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
				fg = "#3b4261",
				bg = "#7aa2f7",
				prefix = { fg = "#3b4261", bg = "#7aa2f7", bold = true },
				important = { fg = "#f7768e", bg = "#7aa2f7", bold = true },
			},
			prefix = "󰓹 ",
			suggestions = true,
			recent_tags = true,
			max_recent = 10,
			hierarchical = true,
			separator = "/",
		},
		attachments = {
			enabled = true,
			storage = "local", -- "local" or "git"
			path = "~/.local/share/lazydo/attachments",
			max_size = 10 * 1024 * 1024, -- 10MB
			allowed_types = {
				"image/*",
				"text/*",
				"application/pdf",
			},
		},

		templates = {
			enabled = true,
			path = "~/.config/lazydo/templates",
			default_template = "basic",
		},
		relations = {
			enabled = true,
			types = {
				"blocks",
				"depends_on",
				"related_to",
				"duplicates",
			},
		},
		priority_levels = {
			enabled = true,
			levels = {
				urgent = { icon = "‼", color = "#db4b4b" },
				high = { icon = "↑", color = "#f7768e" },
				medium = { icon = "○", color = "#e0af68" },
				low = { icon = "↓", color = "#9ece6a" },
			},
		},
		workflow = {
			enabled = true,
			statuses = {
				"pending",
				"in_progress",
				"blocked",
				"done",
				"cancelled",
			},
			transitions = {
				pending = { "in_progress", "cancelled" },
				in_progress = { "blocked", "done", "pending" },
				blocked = { "in_progress", "cancelled" },
				done = { "pending" },
				cancelled = { "pending" },
			},
		},
		metadata = {
			enabled = true,
			display = true,
			colors = {
				key = { fg = "#c0caf5", bg = "#bb9af7", bold = true },
				value = { fg = "#c0caf5", bg = "#7dcfff" },
				section = { fg = "#c0caf5", bg = "#bb9af7", bold = true, italic = true },
			},
			schema = {
				enabled = true,
				properties = {
					assignee = { type = "string" },
					category = { type = "string" },
					effort = { type = "number", min = 1, max = 5 },
					project = { type = "string" },
				},
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
		width = 0.8, -- Percentage of screen width
		height = 0.8, -- Percentage of screen height
		spacing = 1, -- Lines between tasks
		task_padding = 1, -- Padding around task content
		metadata_position = "bottom", -- "bottom" or "right"
	},
	notifications = {
		enabled = true,
		timeout = 2000,
		icons = {
			info = "",
			warn = "",
			error = "",
		},
	},
	integrations = {
		telescope = {
			enabled = true,
		},
		which_key = {
			enabled = true,
		},
		nvim_notify = {
			enabled = true,
		},
		calendar = {
			enabled = true,
			mark_tasks = true,
		},
	},
	persistence = {
		format = "json", -- "json" or "sqlite"
		backup = {
			enabled = true,
			interval = 3600, -- 1 hour
			keep_count = 5,
		},
		sync = {
			enabled = false,
			provider = "git", -- "git" or "custom"
			auto_push = true,
			auto_pull = true,
			interval = 300, -- 5 minutes
		},
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
