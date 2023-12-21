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

local dashboard = require("alpha.themes.dashboard")
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
local Config = theta.config
local butts = {
	type = "group",
	val = {
		{ type = "text", val = fortune(), opts = { hl = "SpecialComment", position = "center" } },
		{ type = "padding", val = 3 },
		dashboard.button("f", "  Find file", ":Telescope find_files <CR>"),
		dashboard.button("e", "  New file", ":ene <BAR> startinsert <CR>"),
		dashboard.button("r", "  Recently used files", ":Telescope oldfiles <CR>"),
		dashboard.button("t", "  Find text", ":Telescope live_grep <CR>"),
		dashboard.button("l", "  Lazy", ":Lazy <CR>"),
		dashboard.button("c", "  Configuration", ":e $MYVIMRC <CR>"),
		dashboard.button("q", "  Quit Neovim", ":qa<CR>"),
		{ type = "padding", val = 3 },
		{
			type = "text",
			val = "Explore Beyond Your Brain's Capabilities...",
			opts = { hl = "SpecialComment", position = "center" },
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
