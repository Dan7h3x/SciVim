return {
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPost", "BufNewFile", "BufWritePre", "VeryLazy" },

		opts = {
			signs = {
				add = { text = "▎" },
				change = { text = "▎" },
				delete = { text = "" },
				topdelete = { text = "" },
				changedelete = { text = "▎" },
				untracked = { text = "▎" },
			},
			signs_staged = {
				add = { text = "▎" },
				change = { text = "▎" },
				delete = { text = "" },
				topdelete = { text = "" },
				changedelete = { text = "▎" },
			},
			on_attach = function(buffer)
				local gs = package.loaded.gitsigns

				local function map(mode, l, r, desc)
					vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
				end

        -- stylua: ignore start
        map("n", "]h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gs.nav_hunk("next")
          end
        end, "Next Hunk")
        map("n", "[h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gs.nav_hunk("prev")
          end
        end, "Prev Hunk")
        map("n", "]H", function() gs.nav_hunk("last") end, "Last Hunk")
        map("n", "[H", function() gs.nav_hunk("first") end, "First Hunk")
        map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
        map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
        map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
        map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
        map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
        map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
        map("n", "<leader>ghb", function() gs.toggle_current_line_blame() end, "Blame Line")
        map("n", "<leader>ghB", function() gs.blame() end, "Blame Buffer")
        map("n", "<leader>ghd", gs.diffthis, "Diff This")
        map("n", "<leader>ghD", function() gs.diffthis("~") end, "Diff This ~")
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
			end,
		},
	},
	{ -- lightweight git client
		"chrisgrieser/nvim-tinygit",
		event = "VeryLazy", -- load for status line component
		keys = {
			-- stylua: ignore start
			{ "<leader>Gc", function() require("tinygit").smartCommit { pushIfClean = true } end, desc = "󰊢 Smart-Commit & Push", nowait = true },
			{ "<leader>GC", function() require("tinygit").smartCommit { pushIfClean = false } end, desc = "󰊢 Smart-Commit" },
			{ "<leader>Ga", function() require("tinygit").interactiveStaging() end, desc = "󰊢 Interactive Staging" },
			{ "<leader>Gp", function() require("tinygit").push { pullBefore = true } end, desc = "󰊢 Pull & Push" },
			{ "<leader>GP", function() require("tinygit").push { createGitHubPr = true } end, desc = " Push & PR" },
			{ "<leader>Gf", function() require("tinygit").fixupCommit { autoRebase = true } end, desc = "󰊢 Fixup & Rebase" },
			{ "<leader>Gm", function() require("tinygit").amendNoEdit { forcePushIfDiverged = true } end, desc = "󰊢 Amend-No-Edit & F-Push" },
			{ "<leader>GM", function() require("tinygit").amendOnlyMsg { forcePushIfDiverged = true } end, desc = "󰊢 Amend Only Msg & F-Push" },
			{ "<leader>Gi", function() require("tinygit").issuesAndPrs { state = "open" } end, desc = " Open Issues" },
			{ "<leader>GI", function() require("tinygit").issuesAndPrs { state = "closed" } end, desc = " Closed Issues" },
			{ "<leader>Gd", function() require("tinygit").searchFileHistory() end, desc = "󰢷 File History" },
			{ "<leader>GD", function() require("tinygit").functionHistory() end, desc = "󰢷 Function History" },
			{ "<leader>g<D-d>", function() require("tinygit").lineHistory() end, mode = { "n", "x" }, desc = "󰢷 Line History" },
			{ "<leader>Gu", function() require("tinygit").githubUrl() end, mode = { "n", "x" }, desc = " GitHub URL" },
			{ "<leader>gU", function() require("tinygit").githubUrl("repo") end, mode = { "n", "x" }, desc = " GitHub Repo URL" },
			{ "<leader>uc", function() require("tinygit").undoLastCommitOrAmend() end, desc = "󰊢 Undo Last Commit/Amend" },
			{ "<leader>Gt", function() require("tinygit").stashPush() end, desc = "󰜦 Stash Push" },
			{ "<leader>GT", function() require("tinygit").stashPop() end, desc = "󰜦 Stash Pop" },
			{ "<leader>G#", function() require("tinygit").openIssueUnderCursor() end, desc = " Open Issue under Cursor" },
			-- stylua: ignore end
		},
		opts = {
			commitMsg = {
				commitPreview = true,
				conventionalCommits = { enforce = true },
				spellcheck = true,
				keepAbortedMsgSecs = 60 * 10, -- 10 mins
				insertIssuesOnHash = { enabled = true, next = "#" },
				openReferencedIssue = true,
			},
			historySearch = {
				autoUnshallowIfNeeded = true,
				diffPopup = {
					width = 0.9,
					height = 0.9,
					border = vim.g.borderStyle,
				},
			},
			statusline = {
				blame = {
					hideAuthorNames = { "Dan7h3x", "mahdi" },
					ignoreAuthors = { "🤖 automated" },
					maxMsgLen = 50,
				},
			},
		},
		config = function(_, opts)
			require("tinygit").setup(opts)
		end,
	},
}
