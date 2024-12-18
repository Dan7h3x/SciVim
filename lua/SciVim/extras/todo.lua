-- Define the TodoManager class
local TodoManager = {}
TodoManager.__index = TodoManager

-- Constructor for the TodoManager class
function TodoManager:new()
	local self = setmetatable({}, TodoManager)
	self.tasks = {} -- Store tasks in a table
	return self
end

-- Function to add a new task
function TodoManager:add_task(title, due_date, subtasks, note)
	table.insert(self.tasks, {
		title = title,
		due_date = due_date,
		subtasks = subtasks or {},
		note = note or "",
		completed = false,
	})
end

-- Function to toggle task completion status
function TodoManager:toggle_task(index)
	if self.tasks[index] then
		self.tasks[index].completed = not self.tasks[index].completed
	end
end

-- Function to toggle subtask completion status
function TodoManager:toggle_subtask(task_index, subtask_index)
	if self.tasks[task_index] and self.tasks[task_index].subtasks[subtask_index] then
		self.tasks[task_index].subtasks[subtask_index].completed =
			not self.tasks[task_index].subtasks[subtask_index].completed
	end
end

-- Function to render the TodoManager UI in a buffer
function TodoManager:render()
	-- Create a new scratch buffer
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "modifiable", true)

	-- Define the UI layout
	local lines = {
		"+-------------------------------------------------------------------------------------+",
		"|                                  Todo Manager                                      |",
		"+-------------------------------------------------------------------------------------+",
		"|                                                                                     |",
		"|  [Header]                                                                           |",
		"|  ===================================================================================|",
		"|  Welcome to your Todo Manager! Use this template to organize your tasks effectively.|",
		"|  - Add tasks with titles, due dates, subtasks, and notes.                           |",
		"|  - Use the toggle status to mark tasks as completed or pending.                     |",
		"|                                                                                     |",
		"+-------------------------------------------------------------------------------------+",
		"|                                                                                     |",
		"|  [Task Section]                                                                     |",
		"|  -----------------------------------------------------------------------------------|",
	}

	-- Add tasks to the UI
	for i, task in ipairs(self.tasks) do
		local status = task.completed and "[x]" or "[ ]"
		table.insert(lines, string.format("|  %s %s", status, task.title))
		table.insert(lines, string.format("|      Due Date: %s", task.due_date))
		for j, subtask in ipairs(task.subtasks) do
			local sub_status = subtask.completed and "[x]" or "[ ]"
			table.insert(lines, string.format("|      - %s %s", sub_status, subtask.title))
		end
		table.insert(lines, string.format("|      Note: %s", task.note))
		table.insert(lines, "|  -----------------------------------------------------------------------------------|")
	end

	-- Add footer
	table.insert(lines, "|                                                                                     |")
	table.insert(lines, "+-------------------------------------------------------------------------------------+")
	table.insert(lines, "|                                                                                     |")
	table.insert(lines, "|  [Footer]                                                                           |")
	table.insert(lines, "|  ===================================================================================|")
	table.insert(lines, "|  Hints:                                                                             |")
	table.insert(lines, "|  - Use [ ] for pending tasks and [x] for completed tasks.                           |")
	table.insert(lines, "|  - Indent subtasks for better readability.                                          |")
	table.insert(lines, "|  - Add due dates and notes to keep track of important details.                      |")
	table.insert(lines, "|  - Customize this template as needed to fit your workflow.                          |")
	table.insert(lines, "|                                                                                     |")
	table.insert(lines, "+-------------------------------------------------------------------------------------+")

	-- Set the buffer content
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)

	-- Open the buffer in a new window
	vim.api.nvim_command("split TodoManager")
	vim.api.nvim_win_set_buf(0, buf)
end

-- Function to initialize the plugin
function TodoManager:init()
	-- Add some example tasks
	self:add_task("Task Title 1", "2023-10-15", {
		{ title = "Subtask 1", completed = false },
		{ title = "Subtask 2", completed = false },
		{ title = "Subtask 3", completed = false },
	}, "Add any additional notes or details here.")

	self:add_task("Task Title 2", "2023-10-16", {
		{ title = "Subtask 1", completed = false },
		{ title = "Subtask 2", completed = false },
	}, "Add any additional notes or details here.")

	self:add_task("Task Title 3", "2023-10-17", {
		{ title = "Subtask 1", completed = true },
		{ title = "Subtask 2", completed = true },
	}, "This task is completed.")

	-- Render the UI
	self:render()
end

-- Create an instance of the TodoManager and initialize it
local todo_manager = TodoManager:new()
todo_manager:init()
