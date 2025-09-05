local M = {}
local cache_file = vim.fn.expand("~/.cache/nvim/recent_dirs.json")
local cache_limit = 30

local function ensure_cache_file()
	local dir = vim.fn.fnamemodify(cache_file, ":h")
	if vim.fn.isdirectory(dir) == 0 then
		vim.fn.mkdir(dir, "p")
	end
	if vim.fn.filereadable(cache_file) == 0 then
		vim.fn.writefile({ "{}" }, cache_file)
	end
end

local function read_cache()
	ensure_cache_file()
	local file = io.open(cache_file, "r")
	if not file then
		return {}
	end
	local content = file:read("*a")
	file:close()
	return vim.fn.json_decode(content) or {}
end

local function write_cache(cache)
	ensure_cache_file()
	local file = io.open(cache_file, "w")
	if file then
		file:write(vim.fn.json_encode(cache))
		file:close()
	end
end

local function add_to_cache(dir)
	local cache = read_cache()
	-- Remove the directory if it already exists in the cache
	for cached_dir, _ in pairs(cache) do
		if cached_dir == dir then
			cache[cached_dir] = nil
			break
		end
	end
	cache[dir] = os.time()
	local cache_size = vim.tbl_count(cache)
	if cache_size > cache_limit then
		local oldest_dir, oldest_timestamp
		for d, timestamp in pairs(cache) do
			if not oldest_timestamp or timestamp < oldest_timestamp then
				oldest_dir, oldest_timestamp = d, timestamp
			end
		end
		if oldest_dir then
			cache[oldest_dir] = nil
		end
	end
	write_cache(cache)
end

local function sort_cache(cache)
	local dirs = {}
	for dir, timestamp in pairs(cache) do
		table.insert(dirs, { dir = dir, timestamp = timestamp })
	end
	table.sort(dirs, function(a, b)
		return a.timestamp > b.timestamp
	end)
	return dirs
end

local function notify_directory_change(dir)
	local project_root =
		vim.fn.systemlist("git -C " .. vim.fn.shellescape(dir) .. " rev-parse --show-toplevel 2>/dev/null")
	local is_git_repo = #project_root > 0 and project_root[1] ~= ""

	local display_path
	if is_git_repo then
		display_path = "[Git Root] " .. project_root[1]
	else
		display_path = "[Dir] " .. dir
	end

	local cache = read_cache()
	local cache_size = vim.tbl_count(cache)

	-- Notify the user
	vim.notify(display_path, vim.log.levels.INFO, {
		title = string.format("Directory Changed (Cache: %d/%d)", cache_size, cache_limit),
		timeout = 2000,
		icon = "",
		on_open = function(win)
			vim.api.nvim_set_option_value("winhl", "Normal:NormalFloat", { win = win })
		end,
	})
end
function M.CdFzf()
	local fd_cmd = "fd -a --type d --hidden --exclude .git --exclude node_modules --exclude .cache --follow"
	local dirs = vim.fn.systemlist(fd_cmd)

	local cache = read_cache()
	local sorted_cache = sort_cache(cache)

	local combined_dirs = {}
	for _, entry in ipairs(sorted_cache) do
		table.insert(combined_dirs, entry.dir)
	end
	for _, dir in ipairs(dirs) do
		if not cache[dir] then
			table.insert(combined_dirs, dir)
		end
	end

	require("fzf-lua").fzf_exec(combined_dirs, {
		prompt = "Change Directory to :> ",
		preview = [[exa -T -L 2 -G --icons --git-ignore --color=always {}]],
		actions = {
			["default"] = function(selected)
				if selected and #selected > 0 then
					local dir = selected[1]
					vim.cmd("cd " .. vim.fn.fnameescape(dir))
					add_to_cache(dir)
					notify_directory_change(dir)
				end
			end,
		},
		winopts = {
			height = 0.8,
			width = 0.9,
			preview = {
				hidden = false,
				vertical = "up:45%",
				horizontal = "right:50%",
			},
		},
	})
end

return M
