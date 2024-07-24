return {
	{
		"frabjous/knap", -- LaTeX builder and previewer
		lazy = true,
		keys = {
			{
				"<F2>",
				function()
					require("knap").process_once()
				end,
				desc = "LaTeX Process",
			},
			{
				"<F3>",
				function()
					require("knap").close_viewer()
				end,
				desc = "Close Viewer",
			},
			{
				"<F4>",
				function()
					require("knap").toggle_autopreviewing()
				end,
				desc = "Toggle Autopreviewing",
			},
			{
				"<F5>",
				function()
					require("knap").forward_jump()
				end,
				desc = "SyncTex",
			},
		},
		config = function()
			local gknapsettings = {
				htmloutputext = "html",
				htmltohtml = "none",
				htmltohtmlviewerlaunch = "chromium %outputfile%",
				htmltohtmlviewerrefresh = "none",
				mdoutputext = "html",
				mdtohtml = "pandoc --standalone %docroot% -o %outputfile%",
				mdtohtmlviewerlaunch = "chromium %outputfile%",
				mdtohtmlviewerrefresh = "none",
				mdtopdf = "pandoc %docroot% -o %outputfile%",
				mdtopdfviewerlaunch = "sioyek %outputfile%",
				mdtopdfviewerrefresh = "none",
				markdownoutputext = "html",
				markdowntohtml = "pandoc --standalone %docroot% -o %outputfile%",
				markdowntohtmlviewerlaunch = "chromium %outputfile%",
				markdowntohtmlviewerrefresh = "none",
				markdowntopdf = "pandoc %docroot% -o %outputfile%",
				markdowntopdfviewerlaunch = "sioyek %outputfile%",
				markdowntopdfviewerrefresh = "none",
				texoutputext = "pdf",
				textopdf = "pdflatex -interaction=batchmode -halt-on-error -synctex=1 %docroot%",
				--[[
  -- Zathura
  --]]
				textopdfviewerlaunch = "zathura --synctex-editor-command 'nvim --headless -es --cmd \"lua require('\"'\"'knaphelper'\"'\"').relayjump('\"'\"'%servername%'\"'\"','\"'\"'%{input}'\"'\"',%{line},0)\"' %outputfile%",
				textopdfviewerrefresh = "none",
				textopdfforwardjump = "zathura --synctex-forward=%line%:%column%:%srcfile% %outputfile%",
				-- [[
				-- Sioyek
				-- ]]
				-- textopdfviewerlaunch = "sioyek --inverse-search 'nvim --headless -es --cmd \"lua require('\"'\"'knaphelper'\"'\"').relayjump('\"'\"'%servername%'\"'\"','\"'\"'%1'\"'\"',%2,0)\"' --new-window %outputfile%",
				-- textopdfviewerrefresh = "none",
				-- textopdfforwardjump = "sioyek --inverse-search 'nvim --headless -es --cmd \"lua require('\"'\"'knaphelper'\"'\"').relayjump('\"'\"'%servername%'\"'\"','\"'\"'%1'\"'\"',%2,0)\"' --reuse-window --forward-search-file %srcfile% --forward-search-line %line% %outputfile%",
				textopdfshorterror = 'A=%outputfile% ; LOGFILE="${A%.pdf}.log" ; rubber-info "$LOGFILE" 2>&1 | head -n 1',
				delay = 150,
			}

			_G.xelatexcheck = function()
				local isxelatex = false
				local fifteenlines = vim.api.nvim_buf_get_lines(0, 0, 15, false)
				for l, line in ipairs(fifteenlines) do
					if
						(line:lower():match("xelatex"))
						or (line:match("\\usepackage[^}]*mathspec"))
						or (line:match("\\usepackage[^}]*fontspec"))
						or (line:match("\\usepackage[^}]*unicode-math"))
					then
						isxelatex = true
						break
					end
				end
				if isxelatex then
					local knapsettings = vim.b.knap_settings or {}
					knapsettings["textopdf"] = "xelatex -interaction=batchmode -halt-on-error -synctex=1 %docroot%"
					vim.b.knap_settings = knapsettings
				end
			end
			vim.api.nvim_create_autocmd({ "BufRead" }, { pattern = { "*.tex" }, callback = xelatexcheck })

			vim.g.knap_settings = gknapsettings
		end,
	},
	{
		"Vigemus/iron.nvim",
		event = "VeryLazy",
		config = function()
			local iron = require("iron.core")
			local view = require("iron.view")
			local fts = require("iron.fts")
			iron.setup({
				config = {
					-- Whether a repl should be discarded or not
					scratch_repl = true,
					-- Your repl definitions come here
					repl_definition = {
						sh = {
							-- Can be a table or a function that
							-- returns a table (see below)
							command = { "zsh" },
						},
						python = fts.python.ipython,
					},
					-- How the repl window will be displayed
					-- See below for more information
					repl_open_cmd = view.split("%30", {
						winfixwidth = true,
						winfixheight = true,
						number = false,
					}),
				},
				-- Iron doesn't set keymaps by default anymore.
				-- You can set them here or manually add keymaps to the functions in iron.core
				keymaps = {
					send_file = "<space>rt",
					send_line = "<space>rl",
					send_until_cursor = "<space>rc",
					exit = "<space>rq",
					send_motion = "<space>re",
				},
				-- If the highlight is on, you can change how it looks
				-- For the available options, check nvim_set_hl
				highlight = { italic = true },
				ignore_blank_lines = true, -- ignore blank lines when sending visual select lines
			})
		end,
	},

	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			opts.highlight = opts.highlight or {}
			if type(opts.ensure_installed) == "table" then
				vim.list_extend(opts.ensure_installed, { "bibtex" })
			end
			if type(opts.highlight.disable) == "table" then
				vim.list_extend(opts.highlight.disable, { "latex" })
			else
				opts.highlight.disable = { "latex" }
			end
		end,
	},
	{
		"lervag/vimtex",
		lazy = false, -- we don't want to lazy load VimTeX
		-- tag = "v2.15", -- uncomment to pin to a specific release
		init = function()
			-- VimTeX configuration goes here, e.g.
			vim.g.vimtex_view_method = "zathura"
			vim.g.vimtex_mappings_disable = { ["n"] = { "K" } } -- disable `K` as it conflicts with LSP hover
		end,
		ft = "tex",
	},
}
