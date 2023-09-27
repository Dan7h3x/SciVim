local status_ok, alpha = pcall(require, "alpha")
if not status_ok then
	return
end

local dashboard = require("alpha.themes.dashboard")
local theta = require("alpha.themes.theta")
local fortune = require("alpha.fortune")
local NvimPy = {
	[[--------------------------------------------------]],
	[[ ███╗   ██╗██╗   ██╗██╗███╗   ███╗██████╗ ██╗   ██╗ ]],
	[[ ████╗  ██║██║   ██║██║████╗ ████║██╔══██╗╚██╗ ██╔╝ ]],
	[[ ██╔██╗ ██║██║   ██║██║██╔████╔██║██████╔╝ ╚████╔╝  ]],
	[[ ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║██╔═══╝   ╚██╔╝   ]],
	[[ ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║██║        ██║    ]],
	[[ ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝╚═╝        ╚═╝    ]],
	[[--------------------------------------------------]],
}
local function lineToStartGradient(lines)
	local out = {}
	for i, line in ipairs(lines) do
		table.insert(out, { hi = "StartLogo" .. i, line = line })
	end
	return out
end

local function lineToStartPopGradient(lines)
	local out = {}
	for i, line in ipairs(lines) do
		local hi = "StartLogo" .. i
		if i <= 6 then
			hi = "StartLogo" .. i + 6
		elseif i > 6 and i <= 12 then
			hi = "StartLogoPop" .. i - 6
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
		table.insert(out, { hi = "StartLogo" .. n, line = line })
	end
	return out
end

local NvimPy1 = lineToStartPopGradient(NvimPy)
local NvimPy2 = lineToStartShiftGradient(NvimPy)
local NvimPy3 = lineToStartGradient(NvimPy)
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
