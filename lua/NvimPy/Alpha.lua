local status_ok, alpha = pcall(require, "alpha")
if not status_ok then
	return
end

--[[
-- local Highlights for NvimPy
--]]
vim.api.nvim_set_hl(0, "NvimPy1", { fg = "#14067E", ctermfg = 18 })
vim.api.nvim_set_hl(0, "NvimPy2", { fg = "#15127B", ctermfg = 18 })
vim.api.nvim_set_hl(0, "NvimPy3", { fg = "#171F78", ctermfg = 18 })
vim.api.nvim_set_hl(0, "NvimPy4", { fg = "#182B75", ctermfg = 18 })
vim.api.nvim_set_hl(0, "NvimPy5", { fg = "#193872", ctermfg = 23 })
vim.api.nvim_set_hl(0, "NvimPy6", { fg = "#1A446E", ctermfg = 23 })
vim.api.nvim_set_hl(0, "NvimPy7", { fg = "#1C506B", ctermfg = 23 })
vim.api.nvim_set_hl(0, "NvimPy8", { fg = "#1D5D68", ctermfg = 23 })
vim.api.nvim_set_hl(0, "NvimPy9", { fg = "#1E6965", ctermfg = 23 })
vim.api.nvim_set_hl(0, "NvimPy10", { fg = "#1F7562", ctermfg = 29 })
vim.api.nvim_set_hl(0, "NvimPy11", { fg = "#21825F", ctermfg = 29 })
vim.api.nvim_set_hl(0, "NvimPy12", { fg = "#228E5C", ctermfg = 29 })
vim.api.nvim_set_hl(0, "NvimPy13", { fg = "#239B59", ctermfg = 29 })
vim.api.nvim_set_hl(0, "NvimPy14", { fg = "#24A755", ctermfg = 29 })
vim.api.nvim_set_hl(0, "NvimPy15", { fg = "#26B352", ctermfg = 29 })
vim.api.nvim_set_hl(0, "NvimPy16", { fg = "#27C04F", ctermfg = 29 })
vim.api.nvim_set_hl(0, "NvimPy17", { fg = "#28CC4C", ctermfg = 41 })
vim.api.nvim_set_hl(0, "NvimPy18", { fg = "#29D343", ctermfg = 41 })
vim.api.nvim_set_hl(0, "NvimPyPy1", { fg = "#EC9F05", ctermfg = 214 })
vim.api.nvim_set_hl(0, "NvimPyPy2", { fg = "#F08C04", ctermfg = 208 })
vim.api.nvim_set_hl(0, "NvimPyPy3", { fg = "#F37E03", ctermfg = 208 })
vim.api.nvim_set_hl(0, "NvimPyPy4", { fg = "#F77002", ctermfg = 202 })
vim.api.nvim_set_hl(0, "NvimPyPy5", { fg = "#FB5D01", ctermfg = 202 })
vim.api.nvim_set_hl(0, "NvimPyPy6", { fg = "#FF4E00", ctermfg = 202 })
--######################################

local if_nil = vim.F.if_nil
local leader = "SPC"
local function button(sc, txt, keybind, hl_opts, keybind_opts)
	local sc_ = sc:gsub("%s", ""):gsub(leader, "<leader>")

	local opts = {
		position = "center",
		hl = hl_opts,
		shortcut = sc,
		cursor = 2,
		width = 50,
		align_shortcut = "right",
		hl_shortcut = "Keyword",
	}
	if keybind then
		keybind_opts = if_nil(keybind_opts, { noremap = true, silent = true, nowait = true })
		opts.keymap = { "n", sc_, keybind, keybind_opts }
	end

	local function on_press()
		local key = vim.api.nvim_replace_termcodes(keybind or sc_ .. "<Ignore>", true, false, true)
		vim.api.nvim_feedkeys(key, "t", false)
	end

	return {
		type = "button",
		val = txt,
		on_press = on_press,
		opts = opts,
	}
end

--#####################################
local theta = require("alpha.themes.theta")
local fortune = require("alpha.fortune")
local NvimPyH1 = {
	[[  ███╗   ██╗██╗   ██╗██╗███╗   ███╗██████╗ ██╗   ██╗  ]],
	[[  ████╗  ██║██║   ██║██║████╗ ████║██╔══██╗╚██╗ ██╔╝  ]],
	[[  ██╔██╗ ██║██║   ██║██║██╔████╔██║██████╔╝ ╚████╔╝   ]],
	[[  ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║██╔═══╝   ╚██╔╝    ]],
	[[  ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║██║        ██║     ]],
	[[  ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝╚═╝        ╚═╝     ]],
	[[   ██╗                                                                ██╗   ]],
	[[  ██╔╝                                                                ╚██╗  ]],
	[[ ██╔╝█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗╚██╗ ]],
	[[ ╚██╗╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝██╔╝ ]],
	[[  ╚██╗                                                                ██╔╝  ]],
	[[   ╚═╝                                                                ╚═╝   ]],
	[[    ███████╗██╗  ██╗████████╗██████╗ ███████╗███╗   ███╗███████╗    ]],
	[[    ██╔════╝╚██╗██╔╝╚══██╔══╝██╔══██╗██╔════╝████╗ ████║██╔════╝    ]],
	[[    █████╗   ╚███╔╝    ██║   ██████╔╝█████╗  ██╔████╔██║█████╗      ]],
	[[    ██╔══╝   ██╔██╗    ██║   ██╔══██╗██╔══╝  ██║╚██╔╝██║██╔══╝      ]],
	[[    ███████╗██╔╝ ██╗   ██║   ██║  ██║███████╗██║ ╚═╝ ██║███████╗    ]],
	[[    ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚══════╝    ]],
}
local NvimPyH2 = {
	[[  ███╗   ██╗██╗   ██╗██╗███╗   ███╗██████╗ ██╗   ██╗  ]],
	[[  ████╗  ██║██║   ██║██║████╗ ████║██╔══██╗╚██╗ ██╔╝  ]],
	[[  ██╔██╗ ██║██║   ██║██║██╔████╔██║██████╔╝ ╚████╔╝   ]],
	[[  ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║██╔═══╝   ╚██╔╝    ]],
	[[  ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║██║        ██║     ]],
	[[  ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝╚═╝        ╚═╝     ]],
	[[   ██╗                                                                ██╗   ]],
	[[  ██╔╝                                                                ╚██╗  ]],
	[[ ██╔╝█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗╚██╗ ]],
	[[ ╚██╗╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝██╔╝ ]],
	[[  ╚██╗                                                                ██╔╝  ]],
	[[   ╚═╝                                                                ╚═╝   ]],
	[[ ██████╗ ███████╗██╗   ██╗████████╗██╗███████╗██╗   ██╗██╗      ]],
	[[ ██╔══██╗██╔════╝██║   ██║╚══██╔══╝██║██╔════╝██║   ██║██║      ]],
	[[ ██████╔╝█████╗  ██║   ██║   ██║   ██║█████╗  ██║   ██║██║      ]],
	[[ ██╔══██╗██╔══╝  ██║   ██║   ██║   ██║██╔══╝  ██║   ██║██║      ]],
	[[ ██████╔╝███████╗╚██████╔╝   ██║   ██║██║     ╚██████╔╝███████╗ ]],
	[[ ╚═════╝ ╚══════╝ ╚═════╝    ╚═╝   ╚═╝╚═╝      ╚═════╝ ╚══════╝ ]],
}
local NvimPyH3 = {
	[[ ███╗   ██╗██╗   ██╗██╗███╗   ███╗██████╗ ██╗   ██╗ ]],
	[[ ████╗  ██║██║   ██║██║████╗ ████║██╔══██╗╚██╗ ██╔╝ ]],
	[[ ██╔██╗ ██║██║   ██║██║██╔████╔██║██████╔╝ ╚████╔╝  ]],
	[[ ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║██╔═══╝   ╚██╔╝   ]],
	[[ ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║██║        ██║    ]],
	[[ ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝╚═╝        ╚═╝    ]],
	[[   ██╗                                                                ██╗   ]],
	[[  ██╔╝                                                                ╚██╗  ]],
	[[ ██╔╝█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗╚██╗ ]],
	[[ ╚██╗╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝██╔╝ ]],
	[[  ╚██╗                                                                ██╔╝  ]],
	[[   ╚═╝                                                                ╚═╝   ]],
	[[  █████╗ ██╗    ██╗███████╗███████╗ ██████╗ ███╗   ███╗███████╗ ]],
	[[ ██╔══██╗██║    ██║██╔════╝██╔════╝██╔═══██╗████╗ ████║██╔════╝ ]],
	[[ ███████║██║ █╗ ██║█████╗  ███████╗██║   ██║██╔████╔██║█████╗   ]],
	[[ ██╔══██║██║███╗██║██╔══╝  ╚════██║██║   ██║██║╚██╔╝██║██╔══╝   ]],
	[[ ██║  ██║╚███╔███╔╝███████╗███████║╚██████╔╝██║ ╚═╝ ██║███████╗ ]],
	[[ ╚═╝  ╚═╝ ╚══╝╚══╝ ╚══════╝╚══════╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝ ]],
}
local function lineToStartGradient(lines)
	local out = {}
	for i, line in ipairs(lines) do
		table.insert(out, { hi = "NvimPy" .. i, line = line })
	end
	return out
end

local function lineToStartPopGradient(lines)
	local out = {}
	for i, line in ipairs(lines) do
		local hi = "NvimPy" .. i
		if i <= 6 then
			hi = "NvimPy" .. i + 6
		elseif i > 6 and i <= 12 then
			hi = "NvimPyPy" .. i - 6
		end
		table.insert(out, { hi = hi, line = line })
	end
	return out
end

local function lineToStartShiftGradient(lines)
	local out = {}
	for i, line in ipairs(lines) do
		local n = i
		if i > 6 and i <= 12 then
			n = i + 6
		elseif i > 12 then
			n = i - 6
		end
		table.insert(out, { hi = "NvimPy" .. n, line = line })
	end
	return out
end

local NvimPy1 = lineToStartPopGradient(NvimPyH1)
local NvimPy2 = lineToStartShiftGradient(NvimPyH2)
local NvimPy3 = lineToStartGradient(NvimPyH3)
local Headers = { NvimPy1, NvimPy2, NvimPy3 }

local function headers_chars()
	math.randomseed(os.time())
	return Headers[math.random(#Headers)]
end
local function header_color()
	local lines = {}
	for i, lineConfig in pairs(headers_chars()) do
		local hi = lineConfig.hi
		local line_chars = lineConfig.line
		local line = {
			type = "text",
			val = line_chars,
			opts = {
				hl = hi,
				shrink_margin = false,
				position = "center",
			},
		}
		table.insert(lines, line)
	end

	local output = {
		type = "group",
		val = lines,
		opts = { position = "center" },
	}

	return output
end

local Modules = function()
	local stats = require("lazy").stats()
	local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
	return { "  NvimPy loaded " .. stats.loaded .. "/" .. stats.count .. " plugins in " .. ms .. "ms" }
end

local Config = theta.config
local butts = {
	type = "group",
	val = {
		{ type = "text", val = fortune(), opts = { hl = "NvimPyTeal", position = "center" } },
		{ type = "padding", val = 2 },
		button("f", "  Find file", "<Cmd> Telescope find_files <CR>", "NvimPyBlue"),
		button("e", "  New file", "<Cmd> ene <BAR> startinsert <CR>", "NvimPyCyan"),
		button("r", "  Recently used files", "<Cmd> Telescope oldfiles <CR>", "NvimPyYellow"),
		button("t", "  Find text", "<Cmd> Telescope live_grep <CR>", "NvimPyTeal"),
		button("l", "  Lazy", "<Cmd> Lazy <CR>", "NvimPyPurple"),
		button("c", "  Configuration", "<Cmd> e $MYVIMRC <CR>", "NvimPyOrange"),
		button("q", "  Quit Neovim", "<Cmd> qa<CR>", "NvimPyRed"),
		{ type = "padding", val = 2 },
		{
			type = "text",
			val = "Explore Beyond Your Brain's Capabilities...",
			opts = { hl = "NvimPyTeal", position = "center" },
		},
		{ type = "padding", val = 2 },
		{
			type = "text",
			val = Modules(),
			opts = { hl = "NvimPyPurple", position = "center" },
		},
	},
	position = "center",
}

Config.layout[2] = nil
Config.layout[3] = header_color()
Config.layout[4] = butts
Config.layout[5] = nil
Config.layout[6] = nil

alpha.setup(Config)
