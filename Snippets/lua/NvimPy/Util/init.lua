local Util = require("lazy.core.util")

local M = {}

M.root_patterns = { ".git", "lua" }

---@param on_attach fun(client, buffer)
function M.on_attach(on_attach)
	vim.api.nvim_create_autocmd("LspAttach", {
		callback = function(args)
			local buffer = args.buf
			local client = vim.lsp.get_client_by_id(args.data.client_id)
			on_attach(client, buffer)
		end,
	})
end

---@param plugin string
function M.has(plugin)
	return require("lazy.core.config").spec.plugins[plugin] ~= nil
end

function M.fg(name)
	---@type {foreground?:number}?
	local hl = vim.api.nvim_get_hl and vim.api.nvim_get_hl(0, { name = name })
		or vim.api.nvim_get_hl_by_name(name, true)
	local fg = hl and hl.fg or hl.foreground
	return fg and { fg = string.format("#%06x", fg) }
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

---@param name string
function M.opts(name)
	local plugin = require("lazy.core.config").plugins[name]
	if not plugin then
		return {}
	end
	local Plugin = require("lazy.core.plugin")
	return Plugin.values(plugin, "opts", false)
end

-- returns the root directory based on:
-- * lsp workspace folders
-- * lsp root_dir
-- * root pattern of filename of the current buffer
-- * root pattern of cwd
---@return string
function M.get_root()
	---@type string?
	local path = vim.api.nvim_buf_get_name(0)
	path = path ~= "" and vim.loop.fs_realpath(path) or nil
	---@type string[]
	local roots = {}
	if path then
		for _, client in pairs(vim.lsp.get_active_clients({ bufnr = 0 })) do
			local workspace = client.config.workspace_folders
			local paths = workspace
					and vim.tbl_map(function(ws)
						return vim.uri_to_fname(ws.uri)
					end, workspace)
				or client.config.root_dir and { client.config.root_dir }
				or {}
			for _, p in ipairs(paths) do
				local r = vim.loop.fs_realpath(p)
				if path:find(r, 1, true) then
					roots[#roots + 1] = r
				end
			end
		end
	end
	table.sort(roots, function(a, b)
		return #a > #b
	end)
	---@type string?
	local root = roots[1]
	if not root then
		path = path and vim.fs.dirname(path) or vim.loop.cwd()
		---@type string?
		root = vim.fs.find(M.root_patterns, { path = path, upward = true })[1]
		root = root and vim.fs.dirname(root) or vim.loop.cwd()
	end
	---@cast root string
	return root
end

-- this will return a function that calls telescope.
-- cwd will default to lazyvim.util.get_root
-- for `files`, git_files or find_files will be chosen depending on .git
function M.telescope(builtin, opts)
	local params = { builtin = builtin, opts = opts }
	return function()
		builtin = params.builtin
		opts = params.opts
		opts = vim.tbl_deep_extend("force", { cwd = M.get_root() }, opts or {})
		if builtin == "files" then
			if vim.loop.fs_stat((opts.cwd or vim.loop.cwd()) .. "/.git") then
				opts.show_untracked = true
				builtin = "git_files"
			else
				builtin = "find_files"
			end
		end
		if opts.cwd and opts.cwd ~= vim.loop.cwd() then
			opts.attach_mappings = function(_, map)
				map("i", "<a-c>", function()
					local action_state = require("telescope.actions.state")
					local line = action_state.get_current_line()
					M.telescope(
						params.builtin,
						vim.tbl_deep_extend("force", {}, params.opts or {}, { cwd = false, default_text = line })
					)()
				end)
				return true
			end
		end

		require("telescope.builtin")[builtin](opts)
	end
end

---@type table<string,LazyFloat>
local terminals = {}

-- Opens a floating terminal (interactive by default)
---@param cmd? string[]|string
---@param opts? LazyCmdOptions|{interactive?:boolean, esc_esc?:false, ctrl_hjkl?:false}


---@param silent boolean?
---@param values? {[1]:any, [2]:any}
function M.toggle(option, silent, values)
	if values then
		if vim.opt_local[option]:get() == values[1] then
			vim.opt_local[option] = values[2]
		else
			vim.opt_local[option] = values[1]
		end
		return Util.info("Set " .. option .. " to " .. vim.opt_local[option]:get(), { title = "Option" })
	end
	vim.opt_local[option] = not vim.opt_local[option]:get()
	if not silent then
		if vim.opt_local[option]:get() then
			Util.info("Enabled " .. option, { title = "Option" })
		else
			Util.warn("Disabled " .. option, { title = "Option" })
		end
	end
end

local nu = { number = true, relativenumber = true }
function M.toggle_number()
	if vim.opt_local.number:get() or vim.opt_local.relativenumber:get() then
		nu = { number = vim.opt_local.number:get(), relativenumber = vim.opt_local.relativenumber:get() }
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
		Util.warn("Disabled line numbers", { title = "Option" })
	else
		vim.opt_local.number = nu.number
		vim.opt_local.relativenumber = nu.relativenumber
		Util.info("Enabled line numbers", { title = "Option" })
	end
end

local enabled = true
function M.toggle_diagnostics()
	enabled = not enabled
	if enabled then
		vim.diagnostic.enable()
		Util.info("Enabled diagnostics", { title = "Diagnostics" })
	else
		vim.diagnostic.disable()
		Util.warn("Disabled diagnostics", { title = "Diagnostics" })
	end
end

function M.deprecate(old, new)
	Util.warn(("`%s` is deprecated. Please use `%s` instead"):format(old, new), { title = "LazyVim" })
end

-- delay notifications till vim.notify was replaced or after 500ms


function M.lsp_get_config(server)
	local configs = require("lspconfig.configs")
	return rawget(configs, server)
end

---@param server string
---@param cond fun( root_dir, config): boolean
function M.lsp_disable(server, cond)
	local util = require("lspconfig.util")
	local def = M.lsp_get_config(server)
	def.document_config.on_new_config = util.add_hook_before(
		def.document_config.on_new_config,
		function(config, root_dir)
			if cond(root_dir, config) then
				config.enabled = false
			end
		end
	)
end

---@param name string
---@param fn fun(name:string)
function M.on_load(name, fn)
	local Config = require("lazy.core.config")
	if Config.plugins[name] and Config.plugins[name]._.loaded then
		vim.schedule(function()
			fn(name)
		end)
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



return M
