-- Test suite for terminal.nvim
-- Run with: nvim --headless -c "luafile tests/test.lua" -c "qa!"

local term = require('terminal')
local Terminal = require('terminal.terminal')
local TerminalManager = require('terminal.manager')
local utils = require('terminal.utils')

---@class TestSuite
---@field tests table<string, function>
---@field passed number
---@field failed number
local TestSuite = {}
TestSuite.__index = TestSuite

---Create a new test suite
---@return TestSuite
function TestSuite:new()
  local instance = setmetatable({}, self)
  instance.tests = {}
  instance.passed = 0
  instance.failed = 0
  return instance
end

---Add a test
---@param name string Test name
---@param fn function Test function
function TestSuite:add(name, fn)
  self.tests[name] = fn
end

---Assert equality
---@param actual any Actual value
---@param expected any Expected value
---@param message string|nil Error message
function TestSuite:assert_equal(actual, expected, message)
  if actual ~= expected then
    error(message or string.format('Expected %s, got %s', expected, actual))
  end
end

---Assert truthy
---@param value any Value to check
---@param message string|nil Error message
function TestSuite:assert_true(value, message)
  if not value then
    error(message or 'Expected truthy value')
  end
end

---Assert falsy
---@param value any Value to check
---@param message string|nil Error message
function TestSuite:assert_false(value, message)
  if value then
    error(message or 'Expected falsy value')
  end
end

---Run all tests
function TestSuite:run()
  print('\n=== Running terminal.nvim tests ===\n')
  
  for name, fn in pairs(self.tests) do
    local ok, err = pcall(fn, self)
    if ok then
      self.passed = self.passed + 1
      print('✓ ' .. name)
    else
      self.failed = self.failed + 1
      print('✗ ' .. name)
      print('  Error: ' .. tostring(err))
    end
  end
  
  print('\n=== Test Results ===')
  print(string.format('Passed: %d', self.passed))
  print(string.format('Failed: %d', self.failed))
  print(string.format('Total:  %d', self.passed + self.failed))
  
  if self.failed > 0 then
    os.exit(1)
  end
end

-- Create test suite
local suite = TestSuite:new()

-- ==============================================================================
-- Terminal Class Tests
-- ==============================================================================

suite:add('Terminal:new creates instance', function(self)
  local terminal = Terminal:new('bash')
  self:assert_true(terminal ~= nil, 'Terminal should be created')
  self:assert_equal(terminal.cmd, 'bash', 'Command should be set')
  self:assert_false(terminal.state.is_open, 'Terminal should not be open')
  self:assert_false(terminal.state.is_running, 'Terminal should not be running')
end)

suite:add('Terminal:new accepts options', function(self)
  local terminal = Terminal:new('bash', {
    direction = 'float',
    size = 20,
    close_on_exit = true,
  })
  
  self:assert_equal(terminal.opts.direction, 'float', 'Direction should be set')
  self:assert_equal(terminal.opts.size, 20, 'Size should be set')
  self:assert_true(terminal.opts.close_on_exit, 'close_on_exit should be set')
end)

suite:add('Terminal:_calculate_size works correctly', function(self)
  local terminal = Terminal:new('bash', { direction = 'horizontal', size = 15 })
  local width, height = terminal:_calculate_size()
  
  self:assert_true(width > 0, 'Width should be positive')
  self:assert_equal(height, 15, 'Height should match size')
end)

suite:add('Terminal:_calculate_size handles functions', function(self)
  local terminal = Terminal:new('bash', { 
    direction = 'horizontal', 
    size = function() return 25 end 
  })
  local _, height = terminal:_calculate_size()
  
  self:assert_equal(height, 25, 'Should use function result')
end)

suite:add('Terminal state management', function(self)
  local terminal = Terminal:new('bash')
  
  self:assert_false(terminal:is_open(), 'Should not be open')
  self:assert_false(terminal:is_running(), 'Should not be running')
  
  terminal.state.is_open = true
  terminal.state.is_running = true
  
  -- Note: These will still return false because bufnr/winnr are nil
  -- This is expected behavior - state must match actual Neovim state
end)

-- ==============================================================================
-- TerminalManager Tests
-- ==============================================================================

suite:add('TerminalManager singleton pattern', function(self)
  local manager1 = TerminalManager:get_instance()
  local manager2 = TerminalManager:get_instance()
  
  self:assert_equal(manager1, manager2, 'Should return same instance')
end)

suite:add('TerminalManager:create_terminal', function(self)
  local manager = TerminalManager:get_instance()
  local id = manager:create_terminal('bash')
  
  self:assert_true(id > 0, 'Should return valid ID')
  self:assert_true(manager:get_terminal(id) ~= nil, 'Terminal should exist')
end)

suite:add('TerminalManager:get_or_create', function(self)
  local manager = TerminalManager:get_instance()
  local terminal1 = manager:get_or_create(99, 'bash')
  local terminal2 = manager:get_or_create(99, 'bash')
  
  self:assert_equal(terminal1, terminal2, 'Should return same terminal')
end)

suite:add('TerminalManager:count', function(self)
  local manager = TerminalManager:new()  -- Fresh instance for test
  
  self:assert_equal(manager:count(), 0, 'Should start with 0')
  
  manager:create_terminal('bash')
  self:assert_equal(manager:count(), 1, 'Should have 1 terminal')
  
  manager:create_terminal('bash')
  self:assert_equal(manager:count(), 2, 'Should have 2 terminals')
end)

suite:add('TerminalManager:get_all_ids', function(self)
  local manager = TerminalManager:new()
  
  local id1 = manager:create_terminal('bash')
  local id2 = manager:create_terminal('bash')
  local ids = manager:get_all_ids()
  
  self:assert_equal(#ids, 2, 'Should return 2 IDs')
  self:assert_true(ids[1] == id1 or ids[1] == id2, 'Should contain id1')
  self:assert_true(ids[2] == id1 or ids[2] == id2, 'Should contain id2')
end)

suite:add('TerminalManager:destroy_terminal', function(self)
  local manager = TerminalManager:new()
  local id = manager:create_terminal('bash')
  
  self:assert_true(manager:get_terminal(id) ~= nil, 'Terminal should exist')
  
  manager:destroy_terminal(id)
  
  self:assert_true(manager:get_terminal(id) == nil, 'Terminal should be destroyed')
end)

suite:add('TerminalManager:for_each', function(self)
  local manager = TerminalManager:new()
  manager:create_terminal('bash')
  manager:create_terminal('bash')
  
  local count = 0
  manager:for_each(function(id, terminal)
    count = count + 1
  end)
  
  self:assert_equal(count, 2, 'Should iterate over all terminals')
end)

suite:add('TerminalManager:find', function(self)
  local manager = TerminalManager:new()
  local id1 = manager:create_terminal('bash')
  local id2 = manager:create_terminal('python3')
  
  local found_id, found_term = manager:find(function(id, terminal)
    return terminal.cmd == 'python3'
  end)
  
  self:assert_equal(found_id, id2, 'Should find python3 terminal')
  self:assert_equal(found_term.cmd, 'python3', 'Should return correct terminal')
end)

-- ==============================================================================
-- Utils Tests
-- ==============================================================================

suite:add('utils.is_callable checks functions', function(self)
  self:assert_true(utils.is_callable(function() end), 'Function should be callable')
  self:assert_false(utils.is_callable(5), 'Number should not be callable')
  self:assert_false(utils.is_callable('string'), 'String should not be callable')
end)

suite:add('utils.is_callable checks tables with __call', function(self)
  local callable_table = setmetatable({}, {
    __call = function() end
  })
  
  self:assert_true(utils.is_callable(callable_table), 'Table with __call should be callable')
end)

suite:add('utils.parse_percentage', function(self)
  self:assert_equal(utils.parse_percentage(0.5, 100), 50, 'Should calculate percentage')
  self:assert_equal(utils.parse_percentage(0.8, 200), 160, 'Should calculate percentage')
  self:assert_equal(utils.parse_percentage(50, 100), 50, 'Should use absolute value')
end)

suite:add('utils.validate_opts validates direction', function(self)
  local valid, _ = utils.validate_opts({ direction = 'horizontal' })
  self:assert_true(valid, 'horizontal should be valid')
  
  valid, _ = utils.validate_opts({ direction = 'invalid' })
  self:assert_false(valid, 'invalid should not be valid')
end)

suite:add('utils.validate_opts validates size', function(self)
  local valid, _ = utils.validate_opts({ size = 10 })
  self:assert_true(valid, 'Positive number should be valid')
  
  valid, _ = utils.validate_opts({ size = -5 })
  self:assert_false(valid, 'Negative number should not be valid')
  
  valid, _ = utils.validate_opts({ size = function() return 10 end })
  self:assert_true(valid, 'Function should be valid')
end)

suite:add('utils.clamp', function(self)
  self:assert_equal(utils.clamp(5, 0, 10), 5, 'Should keep value in range')
  self:assert_equal(utils.clamp(-5, 0, 10), 0, 'Should clamp to minimum')
  self:assert_equal(utils.clamp(15, 0, 10), 10, 'Should clamp to maximum')
end)

suite:add('utils.round', function(self)
  self:assert_equal(utils.round(5.4), 5, 'Should round down')
  self:assert_equal(utils.round(5.5), 6, 'Should round up')
  self:assert_equal(utils.round(5.6), 6, 'Should round up')
end)

suite:add('utils.is_empty', function(self)
  self:assert_true(utils.is_empty({}), 'Empty table should be empty')
  self:assert_false(utils.is_empty({ 1 }), 'Table with items should not be empty')
  self:assert_false(utils.is_empty({ a = 1 }), 'Table with keys should not be empty')
end)

suite:add('utils.table_count', function(self)
  self:assert_equal(utils.table_count({}), 0, 'Empty table has 0 elements')
  self:assert_equal(utils.table_count({ 1, 2, 3 }), 3, 'Array has 3 elements')
  self:assert_equal(utils.table_count({ a = 1, b = 2 }), 2, 'Table has 2 elements')
end)

suite:add('utils.escape_pattern', function(self)
  local escaped = utils.escape_pattern('hello.world')
  self:assert_true(escaped:find('%.'), 'Should escape dot')
end)

-- ==============================================================================
-- Plugin API Tests
-- ==============================================================================

suite:add('Plugin API setup', function(self)
  term.setup({
    default_direction = 'float',
    default_size = 20,
  })
  
  self:assert_equal(term.config.default_direction, 'float', 'Config should be set')
  self:assert_equal(term.config.default_size, 20, 'Config should be set')
end)

suite:add('Plugin API create', function(self)
  local id = term.create('bash', { direction = 'horizontal' })
  self:assert_true(id > 0, 'Should return valid ID')
  
  local terminal = term.get_terminal(id)
  self:assert_true(terminal ~= nil, 'Terminal should exist')
  self:assert_equal(terminal.cmd, 'bash', 'Command should be set')
end)

suite:add('Plugin API get_all_ids', function(self)
  -- Create a few terminals
  term.create('bash')
  term.create('bash')
  
  local ids = term.get_all_ids()
  self:assert_true(#ids >= 2, 'Should have at least 2 terminals')
end)

suite:add('Plugin API count', function(self)
  local initial_count = term.count()
  term.create('bash')
  local new_count = term.count()
  
  self:assert_equal(new_count, initial_count + 1, 'Count should increase by 1')
end)

-- ==============================================================================
-- Performance Tests (Memory and Speed)
-- ==============================================================================

suite:add('Terminal creation performance', function(self)
  local start_time = vim.loop.hrtime()
  
  for i = 1, 100 do
    local _ = Terminal:new('bash')
  end
  
  local elapsed = (vim.loop.hrtime() - start_time) / 1e6  -- Convert to ms
  
  -- Should create 100 terminals in less than 100ms (1ms each)
  self:assert_true(elapsed < 100, string.format('Too slow: %fms', elapsed))
  print(string.format('  Created 100 terminals in %.2fms (%.2fms each)', elapsed, elapsed / 100))
end)

suite:add('TerminalManager operations performance', function(self)
  local manager = TerminalManager:new()
  
  -- Create 50 terminals
  for i = 1, 50 do
    manager:create_terminal('bash')
  end
  
  local start_time = vim.loop.hrtime()
  
  -- Perform various operations
  manager:get_all_ids()
  manager:count()
  manager:for_each(function() end)
  
  local elapsed = (vim.loop.hrtime() - start_time) / 1e6
  
  -- Should complete in less than 10ms
  self:assert_true(elapsed < 10, string.format('Too slow: %fms', elapsed))
  print(string.format('  Manager operations completed in %.2fms', elapsed))
end)

-- ==============================================================================
-- Run Tests
-- ==============================================================================

suite:run()

-- Clean up
term.destroy_all()
