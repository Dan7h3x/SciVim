local Picker = require("NvimPy.utils.pickers")

---@type LazyPicker
local picker = {
	name = "telescope",
	commands = {
		files = "find_files",
	},
	---@param builtin string
	---@param opts? NvimPy.utils.pickers.Opts
	open = function(builtin, opts)
		opts = opts or {}
		if opts.cwd and opts.cwd ~= vim.uv.cwd() then
			local function open_cwd_dir()
				local action_state = require("telescope.actions.state")
				local line = action_state.get_current_line()
				require("NvimPy.utils.pickers").open(
					builtin,
					vim.tbl_deep_extend("force", {}, opts or {}, {
						root = false,
						default_text = line,
					})
				)
			end
			---@diagnostic disable-next-line: inject-field
			opts.attach_mappings = function(_, map)
				map("i", "<a-c>", open_cwd_dir, { desc = "Open cwd telescope" })
				return true
			end
		end
		require("telescope.builtin")[builtin](opts)
	end,
}

if not Picker.register(picker) then
	return {}
end

return {

	{
		"nvim-telescope/telescope.nvim",
		event = "VeryLazy",

		dependencies = { "nvim-lua/plenary.nvim", lazy = true },
		keys = {
			{
				"<leader>,",
				"<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>",
				desc = "Switch Buffer",
			},
			{
				"<leader>/",
				Picker("live_grep"),
				desc = "Grep (Root Dir)",
			},
			{
				"<leader>:",
				"<cmd>Telescope command_history<cr>",
				desc = "Command History",
			},
			{
				"<leader><space>",
				Picker("auto"),
				desc = "Find Files (Root Dir)",
			},
			-- find
			{ "<leader>fb", "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>", desc = "Buffers" },
			{
				"<leader>fc",
				Picker.config_files(),
				desc = "Find Config File",
			},
			{
				"<leader>ff",
				Picker("auto"),
				desc = "Find Files (Root Dir)",
			},
			{
				"<leader>fF",
				Picker("auto", { root = false }),
				desc = "Find Files (cwd)",
			},
			{
				"<leader>fg",
				"<cmd>Telescope git_files<cr>",
				desc = "Find Files (git-files)",
			},
			{ "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent" },
			{ "<leader>fR", Picker("oldfiles", { cwd = vim.uv.cwd() }), desc = "Recent (cwd)" },
			-- git
			{ "<leader>gc", "<cmd>Telescope git_commits<CR>", desc = "Commits" },
			{ "<leader>gs", "<cmd>Telescope git_status<CR>", desc = "Status" },
			-- search
			{ '<leader>s"', "<cmd>Telescope registers<cr>", desc = "Registers" },
			{
				"<leader>sa",
				"<cmd>Telescope autocommands<cr>",
				desc = "Auto Commands",
			},
			{ "<leader>sb", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Buffer" },
			{
				"<leader>sc",
				"<cmd>Telescope command_history<cr>",
				desc = "Command History",
			},
			{ "<leader>sC", "<cmd>Telescope commands<cr>", desc = "Commands" },
			{
				"<leader>sd",
				"<cmd>Telescope diagnostics bufnr=0<cr>",
				desc = "Document Diagnostics",
			},
			{
				"<leader>sD",
				"<cmd>Telescope diagnostics<cr>",
				desc = "Workspace Diagnostics",
			},
			{
				"<leader>sg",
				Picker("live_grep"),
				desc = "Grep (Root Dir)",
			},
			{ "<leader>sG", Picker("live_grep", { root = false }), desc = "Grep (cwd)" },
			{ "<leader>sh", "<cmd>Telescope help_tags<cr>", desc = "Help Pages" },
			{
				"<leader>sH",
				"<cmd>Telescope highlights<cr>",
				desc = "Search Highlight Groups",
			},
			{ "<leader>sj", "<cmd>Telescope jumplist<cr>", desc = "Jumplist" },
			{ "<leader>sk", "<cmd>Telescope keymaps<cr>", desc = "Key Maps" },
			{
				"<leader>sl",
				"<cmd>Telescope loclist<cr>",
				desc = "Location List",
			},
			{ "<leader>sM", "<cmd>Telescope man_pages<cr>", desc = "Man Pages" },
			{ "<leader>sm", "<cmd>Telescope marks<cr>", desc = "Jump to Mark" },
			{ "<leader>so", "<cmd>Telescope vim_options<cr>", desc = "Options" },
			{ "<leader>sR", "<cmd>Telescope resume<cr>", desc = "Resume" },
			{
				"<leader>sq",
				"<cmd>Telescope quickfix<cr>",
				desc = "Quickfix List",
			},
			{
				"<leader>sw",
				Picker("grep_string", { word_match = "-w" }),
				desc = "Word (Root Dir)",
			},
			{ "<leader>sW", Picker("grep_string", { root = false, word_match = "-w" }), desc = "Word (cwd)" },
			{
				"<leader>sw",
				Picker("grep_string"),
				mode = "v",
				desc = "Selection (Root Dir)",
			},
			{
				"<leader>sW",
				Picker("grep_string", { root = false }),
				mode = "v",
				desc = "Selection (cwd)",
			},
			{
				"<leader>uC",
				Picker("colorscheme", { enable_preview = true }),
				desc = "Colorscheme with Preview",
			},
		},
		opts = function()
			local actions = require("telescope.actions")

			local open_with_trouble = function(...)
				return require("trouble.sources.telescope").open(...)
			end
			local find_files_no_ignore = function()
				local action_state = require("telescope.actions.state")
				local line = action_state.get_current_line()
				Picker("find_files", { no_ignore = true, default_text = line })()
			end
			local find_files_with_hidden = function()
				local action_state = require("telescope.actions.state")
				local line = action_state.get_current_line()
				Picker("find_files", { hidden = true, default_text = line })()
			end

			return {
				defaults = {
					entry_prefix = "󰄯  ",
					selection_caret = "󰠠  ",
					prompt_prefix = " ",
					layout_strategy = "vertical",
					get_selection_window = function()
						local wins = vim.api.nvim_list_wins()
						table.insert(wins, 1, vim.api.nvim_get_current_win())
						for _, win in ipairs(wins) do
							local buf = vim.api.nvim_win_get_buf(win)
							if vim.bo[buf].buftype == "" then
								return win
							end
						end
						return 0
					end,
					mappings = {
						i = {
							["<c-t>"] = open_with_trouble,
							["<a-t>"] = open_with_trouble,
							["<a-i>"] = find_files_no_ignore,
							["<a-h>"] = find_files_with_hidden,
							["<C-Down>"] = actions.cycle_history_next,
							["<C-Up>"] = actions.cycle_history_prev,
							["<C-f>"] = actions.preview_scrolling_down,
							["<C-b>"] = actions.preview_scrolling_up,
						},
						n = {
							["q"] = actions.close,
						},
					},
				},
			}
		end,
	},
	{
		"stevearc/dressing.nvim",
		lazy = true,
		init = function()
			---@diagnostic disable-next-line: duplicate-set-field
			vim.ui.select = function(...)
				require("lazy").load({ plugins = { "dressing.nvim" } })
				return vim.ui.select(...)
			end
			---@diagnostic disable-next-line: duplicate-set-field
			vim.ui.input = function(...)
				require("lazy").load({ plugins = { "dressing.nvim" } })
				return vim.ui.input(...)
			end
		end,
	},
	{
		"nvim-telescope/telescope.nvim",
		optional = true,
		opts = function(_, opts)
			if not require("NvimPy.utils.init").has("flash.nvim") then
				return
			end
			local function flash(prompt_bufnr)
				require("flash").jump({
					pattern = "^",
					label = { after = { 0, 0 } },
					search = {
						mode = "search",
						exclude = {
							function(win)
								return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "TelescopeResults"
							end,
						},
					},
					action = function(match)
						local picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)
						picker:set_selection(match.pos[1] - 1)
					end,
				})
			end
			opts.defaults = vim.tbl_deep_extend("force", opts.defaults or {}, {
				mappings = { n = { s = flash }, i = { ["<c-s>"] = flash } },
			})
		end,
	},

	{
		"benfowler/telescope-luasnip.nvim",
		event = "VeryLazy",
		config = function()
			require("telescope").load_extension("luasnip")
		end,
	},
	{
		"nvim-telescope/telescope-fzf-native.nvim",
		build = "make",
		lazy = true,
	},
}
