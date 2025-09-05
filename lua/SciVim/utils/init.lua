local utilsLazy = require("lazy.core.util")

---@class SciVim.utils : LazyUtilCore

local M = {}
function M.is_win()
	return vim.uv.os_uname().sysname:find("Windows") ~= nil
end

---@param name string
function M.get_plugin(name)
	return require("lazy.core.config").spec.plugins[name]
end

---@param name string
---@param path string?
function M.get_plugin_path(name, path)
	local plugin = M.get_plugin(name)
	path = path and "/" .. path or ""
	return plugin and (plugin.dir .. path)
end

---@param plugin string
function M.has(plugin)
	return M.get_plugin(plugin) ~= nil
end

---@param extra string
function M.has_extra(extra)
	local Config = require("lazyvim.config")
	local modname = "lazyvim.plugins.extras." .. extra
	return vim.tbl_contains(require("lazy.core.config").spec.modules, modname)
		or vim.tbl_contains(Config.json.data.extras, modname)
end

---@param fn fun()
function M.on_very_lazy(fn)
	vim.api.nvim_create_autocmd("User", {
		pattern = "VeryLazy",
		callback = function()
			fn()
		end,
	})
end

--- This extends a deeply nested list with a key in a table
--- that is a dot-separated string.
--- The nested list will be created if it does not exist.
---@generic T
---@param t T[]
---@param key string
---@param values T[]
---@return T[]?
function M.extend(t, key, values)
	local keys = vim.split(key, ".", { plain = true })
	for i = 1, #keys do
		local k = keys[i]
		t[k] = t[k] or {}
		if type(t) ~= "table" then
			return
		end
		t = t[k]
	end
	return vim.list_extend(t, values)
end

---@param name string
function M.opts(name)
	local plugin = M.get_plugin(name)
	if not plugin then
		return {}
	end
	local Plugin = require("lazy.core.plugin")
	return Plugin.values(plugin, "opts", false)
end

function M.lazy_notify()
	local notifs = {}
	local function temp(...)
		table.insert(notifs, vim.F.pack_len(...))
	end

	local orig = vim.notify
	vim.notify = temp

	local timer = vim.uv.new_timer()
	local check = assert(vim.uv.new_check())

	local replay = function()
		timer:stop()
		check:stop()
		if vim.notify == temp then
			vim.notify = orig -- put back the original notify if needed
		end
		vim.schedule(function()
			---@diagnostic disable-next-line: no-unknown
			for _, notif in ipairs(notifs) do
				vim.notify(vim.F.unpack_len(notif))
			end
		end)
	end

	-- wait till vim.notify has been replaced
	check:start(function()
		if vim.notify ~= temp then
			replay()
		end
	end)
	-- or if it took more than 500ms, then something went wrong
	timer:start(500, 0, replay)
end

function M.is_loaded(name)
	local Config = require("lazy.core.config")
	return Config.plugins[name] and Config.plugins[name]._.loaded
end

---@param name string
---@param fn fun(name:string)
function M.on_load(name, fn)
	if M.is_loaded(name) then
		fn(name)
	else
		vim.api.nvim_create_autocmd("User", {
			pattern = "LazyLoad",
			callback = function(event)
				if event.data == name then
					fn(name)
					return true
				end
			end,
		})
	end
end

-- Wrapper around vim.keymap.set that will
-- not create a keymap if a lazy key handler exists.
-- It will also set `silent` to true by default.
function M.safe_keymap_set(mode, lhs, rhs, opts)
	local keys = require("lazy.core.handler").handlers.keys
	---@cast keys LazyKeysHandler
	local modes = type(mode) == "string" and { mode } or mode

	---@param m string
	modes = vim.tbl_filter(function(m)
		return not (keys.have and keys:have(lhs, m))
	end, modes)

	-- do not create the keymap if a lazy keys handler exists
	if #modes > 0 then
		opts = opts or {}
		opts.silent = opts.silent ~= false
		if opts.remap and not vim.g.vscode then
			---@diagnostic disable-next-line: no-unknown
			opts.remap = nil
		end
		vim.keymap.set(modes, lhs, rhs, opts)
	end
end

---@generic T
---@param list T[]
---@return T[]
function M.dedup(list)
	local ret = {}
	local seen = {}
	for _, v in ipairs(list) do
		if not seen[v] then
			table.insert(ret, v)
			seen[v] = true
		end
	end
	return ret
end

M.CREATE_UNDO = vim.api.nvim_replace_termcodes("<c-G>u", true, true, true)
function M.create_undo()
	if vim.api.nvim_get_mode().mode == "i" then
		vim.api.nvim_feedkeys(M.CREATE_UNDO, "n", false)
	end
end

--- Gets a path to a package in the Mason registry.
--- Prefer this to `get_package`, since the package might not always be
--- available yet and trigger errors.
---@param pkg string
---@param path? string
---@param opts? { warn?: boolean }
function M.get_pkg_path(pkg, path, opts)
	pcall(require, "mason") -- make sure Mason is loaded. Will fail when generating docs
	local root = vim.env.MASON or (vim.fn.stdpath("data") .. "/mason")
	opts = opts or {}
	opts.warn = opts.warn == nil and true or opts.warn
	path = path or ""
	local ret = root .. "/packages/" .. pkg .. "/" .. path
	if opts.warn and not vim.loop.fs_stat(ret) and not require("lazy.core.config").headless() then
		M.warn(
			("Mason package path not found for **%s**:\n- `%s`\nYou may need to force update the package."):format(
				pkg,
				path
			)
		)
	end
	return ret
end

--- Override the default title for notifications.
for _, level in ipairs({ "info", "warn", "error" }) do
	M[level] = function(msg, opts)
		opts = opts or {}
		opts.title = opts.title or "SciVim"
		return utilsLazy[level](msg, opts)
	end
end

local cache = {} ---@type table<(fun()), table<string, any>>
---@generic T: fun()
---@param fn T
---@return T
function M.memoize(fn)
	return function(...)
		local key = vim.inspect({ ... })
		cache[fn] = cache[fn] or {}
		if cache[fn][key] == nil then
			cache[fn][key] = fn(...)
		end
		return cache[fn][key]
	end
end

function M.lsp_get_clients(...)
	---@diagnostic disable-next-line: deprecated
	return vim.fn.has("nvim-0.11") == 1 and vim.lsp.get_clients(...) or vim.lsp.get_active_clients(...)
end

local fast_event_aware_notify = function(msg, level, opts)
	if vim.in_fast_event() then
		vim.schedule(function()
			vim.notify(msg, level, opts)
		end)
	else
		vim.notify(msg, level, opts)
	end
end

function M.info(msg)
	fast_event_aware_notify(msg, vim.log.levels.INFO, {})
end

function M.warn(msg)
	fast_event_aware_notify(msg, vim.log.levels.WARN, {})
end

function M.err(msg)
	fast_event_aware_notify(msg, vim.log.levels.ERROR, {})
end

function M.input(prompt)
	local ok, res
	if vim.ui then
		ok, _ = pcall(vim.ui.input, { prompt = prompt }, function(input)
			res = input
		end)
	else
		ok, res = pcall(vim.fn.input, { prompt = prompt, cancelreturn = 3 })
		if res == 3 then
			ok, res = false, nil
		end
	end
	return ok and res or nil
end

function M.formatexpr()
	if M.has("conform.nvim") then
		return require("conform").formatexpr()
	end

	return vim.lsp.formatexpr({ timeout_ms = 2000 })
end

function M.ai_buffer(ai_type)
	local start_line, end_line = 1, vim.fn.line("$")
	if ai_type == "i" then
		-- Skip first and last blank lines for `i` textobject
		local first_nonblank, last_nonblank = vim.fn.nextnonblank(start_line), vim.fn.prevnonblank(end_line)
		-- Do nothing for buffer with all blanks
		if first_nonblank == 0 or last_nonblank == 0 then
			return { from = { line = start_line, col = 1 } }
		end
		start_line, end_line = first_nonblank, last_nonblank
	end

	local to_col = math.max(vim.fn.getline(end_line):len(), 1)
	return { from = { line = start_line, col = 1 }, to = { line = end_line, col = to_col } }
end
-- register all text objects with which-key
---@param opts table
function M.ai_whichkey(opts)
	local objects = {
		{ " ", desc = "whitespace" },
		{ '"', desc = '" string' },
		{ "'", desc = "' string" },
		{ "(", desc = "() block" },
		{ ")", desc = "() block with ws" },
		{ "<", desc = "<> block" },
		{ ">", desc = "<> block with ws" },
		{ "?", desc = "user prompt" },
		{ "U", desc = "use/call without dot" },
		{ "[", desc = "[] block" },
		{ "]", desc = "[] block with ws" },
		{ "_", desc = "underscore" },
		{ "`", desc = "` string" },
		{ "a", desc = "argument" },
		{ "b", desc = ")]} block" },
		{ "c", desc = "class" },
		{ "d", desc = "digit(s)" },
		{ "e", desc = "CamelCase / snake_case" },
		{ "f", desc = "function" },
		{ "g", desc = "entire file" },
		{ "i", desc = "indent" },
		{ "o", desc = "block, conditional, loop" },
		{ "q", desc = "quote `\"'" },
		{ "t", desc = "tag" },
		{ "u", desc = "use/call" },
		{ "{", desc = "{} block" },
		{ "}", desc = "{} with ws" },
	}

	---@type wk.Spec[]
	local ret = { mode = { "o", "x" } }
	---@type table<string, string>
	local mappings = vim.tbl_extend("force", {}, {
		around = "a",
		inside = "i",
		around_next = "an",
		inside_next = "in",
		around_last = "al",
		inside_last = "il",
	}, opts.mappings or {})
	mappings.goto_left = nil
	mappings.goto_right = nil

	for name, prefix in pairs(mappings) do
		name = name:gsub("^around_", ""):gsub("^inside_", "")
		ret[#ret + 1] = { prefix, group = name }
		for _, obj in ipairs(objects) do
			local desc = obj.desc
			if prefix:sub(1, 1) == "i" then
				desc = desc:gsub(" with ws", "")
			end
			ret[#ret + 1] = { prefix .. obj[1], desc = obj.desc }
		end
	end
	require("which-key").add(ret, { notify = false })
end

-- function M.formatstc()
-- 	local components = {
-- 		-- Line numbers (right-aligned)
-- 		"%=",
-- 		"%{v:relnum ? v:relnum : v:lnum}",
-- 		" ",
--
-- 		-- Git signs (from gitsigns.nvim)
-- 		"%{%v:lnum == 1 ? '' : repeat(' ', len(gitsigns.status_dict()['head']) + 1)%}",
-- 		"%{%v:lnum == 1 ? '' : gitsigns.status_dict()['head'] .. ' '%}",
--
-- 		-- Diagnostic signs (from nvim-lspconfig)
-- 		"%{%v:lnum == 1 ? '' : v:signs.diagnostic_signs%}",
--
-- 		-- Fold markers (if available)
-- 		"%{%v:lnum == 1 ? '' : v:foldlevel ? '' : ' ' %}",
-- 	}
--
-- 	return table.concat(components)
-- end

return M
