---@class Neatools

local M = {}

M.setup = function(opts)
	opts = opts or {}
	if opts.notify.enabled then
		require("neatools.notify").setup(opts.notify)
	end
end

return M
