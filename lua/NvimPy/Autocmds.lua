local function augroup(name)
	return vim.api.nvim_create_augroup("NvimPy_" .. name, { clear = true })
end

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
	group = augroup("auto_create_dir"),
	callback = function(event)
		if event.match:match("^%w%w+://") then
			return
		end
		local file = vim.loop.fs_realpath(event.match) or event.match
		vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
	end,
})

local function file_exists(path)
	local stat = vim.loop.fs_stat(path)
	return stat and stat.type == "file"
end

local function pythonConfig()
	local pypath = vim.fn.getcwd() .. "/pyrightconfig.json"
	if not file_exists(pypath) then
		local temp = [[ {
  "include": [
    "src"
  ],
  "executionEnvironments": [
    {
      "root": "src"
    }
  ]
}
    ]]
		local file = io.open(pypath, "w")
		file:write(temp)
		file:close()
	end
end

vim.api.nvim_create_autocmd({ "FileType" }, {
	group = augroup("PythonConfig"),
	pattern = { "python", "*.py" },
	callback = function()
		pythonConfig()
		vim.opt_local.expandtab = true
		vim.opt_local.shiftwidth = 4
		vim.opt_local.tabstop = 4
		vim.opt_local.softtabstop = 4

		-- folds based on indentation https://neovim.io/doc/user/fold.html#fold-indent
		-- if you are a heavy user of folds, consider the using nvim-ufo plugin
		-- vim.opt_local.foldmethod = "indent"

		-- automatically capitalize boolean values. Useful if you come from a
		-- different language, and lowercase them out of habit.
		vim.cmd.inoreabbrev("<buffer> true True")
		vim.cmd.inoreabbrev("<buffer> false False")

		-- in the same way, we can fix habits regarding comments or None
		vim.cmd.inoreabbrev("<buffer> -- #")
		vim.cmd.inoreabbrev("<buffer> null None")
		vim.cmd.inoreabbrev("<buffer> none None")
		vim.cmd.inoreabbrev("<buffer> nil None")
	end,
})


