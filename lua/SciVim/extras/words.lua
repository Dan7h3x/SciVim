local luasnip = require("luasnip")
local fzf_lua = require("fzf-lua")

local function get_snippet_preview(snippet)
	-- Try to get snippet docstring if available
	if snippet.docstring then
		if type(snippet.docstring) == "table" then
			return table.concat(snippet.docstring, "\n")
		elseif type(snippet.docstring) == "string" then
			return snippet.docstring
		end
	end

	-- Try to get description
	if snippet.description then
		return snippet.description
	end

	-- Fallback to basic info
	local info = {}
	table.insert(info, "Trigger: " .. (snippet.trigger or ""))
	table.insert(info, "Name: " .. (snippet.name or "Unnamed"))
	if snippet.wordTrig ~= nil then
		table.insert(info, "Word Trigger: " .. tostring(snippet.wordTrig))
	end
	if snippet.regTrig then
		table.insert(info, "Regex Trigger: " .. tostring(snippet.regTrig))
	end

	return table.concat(info, "\n")
end

local function list_luasnip_snippets()
	local filetype = vim.o.filetype
	local available_snippets = luasnip.available()[filetype] or {}

	if vim.tbl_isempty(available_snippets) then
		vim.notify("No LuaSnip snippets found for filetype: " .. filetype, vim.log.levels.INFO)
		return
	end

	local snippet_items = {}
	local snippet_map = {}

	for _, snippet in pairs(available_snippets) do
		local display_text = string.format("%-20s │ %s", snippet.trigger, snippet.name or "")
		table.insert(snippet_items, display_text)
		snippet_map[display_text] = snippet
	end

	fzf_lua.fzf_exec(snippet_items, {
		prompt = "LuaSnips❯ ",
		preview = function(items)
			if not items or #items == 0 then
				return ""
			end

			local selected = items[1]
			local snippet = snippet_map[selected]
			if snippet then
				local preview = get_snippet_preview(snippet)
				return preview
			end
			return "No preview available"
		end,
		winopts = {
			height = 0.85,
			width = 0.90,
			preview = {
				vertical = "up:60%",
				horizontal = "right:50%",
			},
		},
		fzf_opts = {
			["--delimiter"] = "│",
			["--with-nth"] = "1,2",
			["--preview-window"] = "right:50%:wrap",
		},
		actions = {
			["default"] = function(selected)
				if not selected or #selected == 0 then
					return
				end

				local snippet = snippet_map[selected[1]]
				if snippet then
					-- Insert the snippet trigger and expand
					vim.api.nvim_put({ snippet.trigger }, "c", false, true)

					-- Move cursor to end of inserted text
					local row, col = unpack(vim.api.nvim_win_get_cursor(0))
					vim.api.nvim_win_set_cursor(0, { row, col + #snippet.trigger })

					-- Expand the snippet
					if luasnip.expandable() then
						luasnip.expand()
					end
				end
			end,
			["ctrl-y"] = function(selected)
				if not selected or #selected == 0 then
					return
				end

				local snippet = snippet_map[selected[1]]
				if snippet then
					-- Just insert the trigger text without expanding
					vim.api.nvim_put({ snippet.trigger }, "c", false, true)
				end
			end,
		},
	})
end

-- Create user command with better options
vim.api.nvim_create_user_command("FzfLuaSnips", list_luasnip_snippets, {
	desc = "List and expand LuaSnips with fzf-lua (Enter: expand, Ctrl-Y: insert trigger only)",
})

-- Optional: Create a keymap for quick access
vim.keymap.set("n", "<leader>sn", list_luasnip_snippets, {
	desc = "FZF LuaSnip snippets",
	silent = true,
})

-- Optional: Insert mode mapping for snippet completion
vim.keymap.set("i", "<C-f>", function()
	list_luasnip_snippets()
end, {
	desc = "Insert LuaSnip snippet",
	silent = true,
})
