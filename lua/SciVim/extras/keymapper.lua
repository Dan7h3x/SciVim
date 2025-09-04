local M = {}

M.keymaps_to_fzf = function()
	local fzf_lua = require("fzf-lua")
	local keymaps = {}
	local mode_icons = {
		n = "N",
		v = "V",
		i = "I",
		t = "T",
		x = "X",
		s = "S",
		o = "O",
	}
	local mode_names = {
		n = "Normal",
		v = "Visual",
		i = "Insert",
		t = "Terminal",
		x = "Visual",
		s = "Select",
		o = "Operator",
	}

	-- Collect all keymaps with rich metadata
	for _, mode in ipairs({ "n", "v", "i", "t", "x", "s", "o" }) do
		for _, kmap in ipairs(vim.api.nvim_get_keymap(mode)) do
			local flags = {}
			if kmap.silent then
				table.insert(flags, "silent")
			end
			if kmap.nowait then
				table.insert(flags, "nowait")
			end
			if kmap.expr then
				table.insert(flags, "expr")
			end
			if kmap.buffer then
				table.insert(flags, "buffer")
			end

			table.insert(keymaps, {
				mode = mode,
				mode_icon = mode_icons[mode],
				mode_name = mode_names[mode],
				lhs = kmap.lhs,
				rhs = kmap.rhs or "N/A",
				desc = kmap.desc or "No description",
				flags = table.concat(flags, ", "),
				buffer_local = kmap.buffer,
				full_text = string.format(
					"%s %s %s → %s | %s",
					mode_icons[mode],
					kmap.lhs:gsub("<", "<"):gsub(">", ">"),
					kmap.rhs and kmap.rhs:gsub("<", "<"):gsub(">", ">") or "N/A",
					kmap.desc or "No description",
					#flags > 0 and table.concat(flags, ", ") or "no flags"
				),
			})
		end
	end

	-- Sort by mode then by key
	table.sort(keymaps, function(a, b)
		if a.mode == b.mode then
			return a.lhs < b.lhs
		end
		return a.mode < b.mode
	end)

	return keymaps
end

M.browse_keymaps = function()
	local fzf_lua = require("fzf-lua")
	local keymaps = M.keymaps_to_fzf()

	fzf_lua.fzf_exec(function(cb)
		for _, kmap in ipairs(keymaps) do
			cb(kmap.full_text)
		end
		cb(nil)
	end, {
		prompt = "🎹 Keymaps❯ ",
		previewer = function(selected, _)
			local kmap = selected[1]
			if not kmap then
				return ""
			end

			-- Find the matching keymap
			for _, k in ipairs(keymaps) do
				if k.full_text == kmap then
					return string.format(
						[[
            Mode:        %s (%s)
            Key:         %s
            Action:      %s
            Description: %s
            Flags:       %s
            Buffer-local: %s
          ]],
						k.mode_name,
						k.mode,
						k.lhs:gsub("<", "<"):gsub(">", ">"),
						k.rhs:gsub("<", "<"):gsub(">", ">"),
						k.desc,
						k.flags ~= "" and k.flags or "none",
						k.buffer_local and "Yes" or "No"
					)
				end
			end
			return "No details available"
		end,
		actions = {
			["default"] = function(selected, _)
				if #selected > 0 then
					local kmap = selected[1]
					-- Just show info, don't execute
					vim.notify("Selected: " .. kmap, vim.log.levels.INFO)
				end
			end,
			["ctrl-e"] = function(selected, _)
				M.export_keymaps()
			end,
			["ctrl-f"] = function(selected, _)
				if #selected > 0 then
					local kmap = selected[1]
					for _, k in ipairs(keymaps) do
						if k.full_text == kmap then
							-- Filter by this keymap's mode
							M.filter_by_mode(k.mode)
							break
						end
					end
				end
			end,
		},
		fzf_opts = {
			["--header"] = "↑↓: navigate • Enter: view • Ctrl-e: export • Ctrl-f: filter mode • Esc: quit",
			["--preview-window"] = "right:60%:wrap",
		},
	})
end

M.filter_by_mode = function(mode_filter)
	local fzf_lua = require("fzf-lua")
	local keymaps = M.keymaps_to_fzf()
	local mode_icons = { n = "N", v = "V", i = "I", t = "T", x = "X", s = "S", o = "O" }

	fzf_lua.fzf_exec(function(cb)
		for _, kmap in ipairs(keymaps) do
			if kmap.mode == mode_filter then
				cb(kmap.full_text)
			end
		end
		cb(nil)
	end, {
		prompt = "🎹 " .. mode_icons[mode_filter] .. " " .. mode_filter:upper() .. " Mode❯ ",
		previewer = function(selected, _)
			local kmap = selected[1]
			if not kmap then
				return ""
			end

			for _, k in ipairs(keymaps) do
				if k.full_text == kmap then
					return string.format(
						[[
            Key:         %s
            Action:      %s
            Description: %s
            Flags:       %s
            Buffer-local: %s
          ]],
						k.lhs:gsub("<", "<"):gsub(">", ">"),
						k.rhs:gsub("<", "<"):gsub(">", ">"),
						k.desc,
						k.flags ~= "" and k.flags or "none",
						k.buffer_local and "Yes" or "No"
					)
				end
			end
			return "No details available"
		end,
	})
end

M.export_keymaps = function()
	local fzf_lua = require("fzf-lua")
	local keymaps = M.keymaps_to_fzf()

	-- Let user choose export format
	fzf_lua.fzf_exec({
		"markdown",
		"json",
		"text",
		"lua table",
	}, {
		prompt = "📁 Export Format❯ ",
		actions = {
			["default"] = function(selected, _)
				if #selected > 0 then
					local format = selected[1]
					M._do_export(keymaps, format)
				end
			end,
		},
	})
end

M._do_export = function(keymaps, format)
	local filename = os.getenv("HOME")
			.. "/.config/nvim/keymaps_export."
			.. ({
				markdown = "md",
				json = "json",
				text = "txt",
				["lua table"] = "lua",
			})[format]
		or "md"

	local content = {}

	if format == "markdown" then
		table.insert(content, "# 🎹 Neovim Keymaps Export")
		table.insert(content, "> Generated: " .. os.date("%Y-%m-%d %H:%M:%S"))
		table.insert(content, "")

		local modes = {}
		for _, kmap in ipairs(keymaps) do
			if not modes[kmap.mode] then
				modes[kmap.mode] = true
				table.insert(content, "## " .. kmap.mode_icon .. " " .. kmap.mode_name .. " Mode")
				table.insert(content, "")
				table.insert(content, "| Key | Action | Description | Flags |")
				table.insert(content, "|-----|--------|-------------|-------|")

				for _, k in ipairs(keymaps) do
					if k.mode == kmap.mode then
						table.insert(
							content,
							string.format(
								"| `%s` | `%s` | %s | %s |",
								k.lhs:gsub("<", "<"):gsub(">", ">"),
								k.rhs:gsub("<", "<"):gsub(">", ">"),
								k.desc,
								k.flags ~= "" and k.flags or "—"
							)
						)
					end
				end
				table.insert(content, "")
			end
		end
	elseif format == "json" then
		local simple_keymaps = {}
		for _, kmap in ipairs(keymaps) do
			table.insert(simple_keymaps, {
				mode = kmap.mode,
				lhs = kmap.lhs,
				rhs = kmap.rhs,
				desc = kmap.desc,
				flags = kmap.flags,
				buffer_local = kmap.buffer_local,
			})
		end
		content = { vim.fn.json_encode(simple_keymaps) }
	elseif format == "lua table" then
		table.insert(content, "return {")
		for _, kmap in ipairs(keymaps) do
			table.insert(
				content,
				string.format(
					'  { mode = "%s", lhs = "%s", rhs = "%s", desc = "%s" },',
					kmap.mode,
					kmap.lhs,
					kmap.rhs,
					kmap.desc
				)
			)
		end
		table.insert(content, "}")
	else -- text format
		for _, kmap in ipairs(keymaps) do
			table.insert(
				content,
				string.format(
					"%s %s → %s | %s [%s]",
					kmap.mode_icon,
					kmap.lhs:gsub("<", "<"):gsub(">", ">"),
					kmap.rhs:gsub("<", "<"):gsub(">", ">"),
					kmap.desc,
					kmap.flags
				)
			)
		end
	end

	-- Write to file
	local file = io.open(filename, "w")
	for _, line in ipairs(content) do
		file:write(line .. "\n")
	end
	file:close()

	-- Show success notification with option to open
	vim.notify("🎉 Exported " .. #keymaps .. " keymaps to " .. filename, vim.log.levels.INFO, {
		on_open = function(win)
			local buf = vim.api.nvim_win_get_buf(win)
			vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", "", {
				callback = function()
					vim.cmd("edit " .. filename)
					vim.api.nvim_win_close(win, true)
				end,
				desc = "Open exported file",
			})
		end,
	})
end

-- Create user commands
vim.api.nvim_create_user_command("KeymapsBrowse", M.browse_keymaps, {
	desc = "Browse keymaps with fzf-lua",
})

vim.api.nvim_create_user_command("KeymapsExport", M.export_keymaps, {
	desc = "Export keymaps to file",
})

return M
