local scroll_count = 0

--- smooth scroll
---@param target_line number
---@param step fun(current_line) {next_line: number, delay: number}
local scroll = function(target_line, step)
	scroll_count = scroll_count + 1
	local current_count = scroll_count
	local line_count = vim.api.nvim_buf_line_count(0)
	local start_line = vim.api.nvim_win_get_cursor(0)[1]
	local column = vim.api.nvim_win_get_cursor(0)[2]
	local end_line
	if target_line > line_count then
		end_line = line_count
	elseif target_line < 1 then
		end_line = 1
	else
		end_line = math.floor(target_line)
	end
	local current_line = start_line
	local scroll_direction
	if start_line < end_line then
		scroll_direction = "down"
	else
		scroll_direction = "up"
	end

	local scroll_step
	scroll_step = function()
		if scroll_count ~= current_count then
			return
		end

		if scroll_direction == "down" and current_line >= end_line then
			return
		end

		if scroll_direction == "up" and current_line <= end_line then
			return
		end

		local cur_step = step(current_line)
		local next_line
		if scroll_direction == "down" and cur_step.next_line > end_line then
			next_line = end_line
		elseif scroll_direction == "up" and cur_step.next_line < end_line then
			next_line = end_line
		else
			next_line = math.floor(cur_step.next_line)
		end

		if next_line == current_line then
			vim.notify("Next line is equal to current line, scroll exits, check your config", vim.log.levels.WARN, {
				title = "scroll.nvim",
			})
			return
		end

		vim.api.nvim_win_set_cursor(0, { next_line, column })
		current_line = next_line
		vim.defer_fn(scroll_step, cur_step.delay)
	end

	scroll_step()
end

return {
	scroll = scroll,
}
