local Point = require("99.geo").Point
local Logger = require("99.logger.logger")
local Request = require("99.request")
local marks = require("99.ops.marks")
local Context = require("99.ops.context")
local editor = require("99.editor")

--- @param res string
--- @param location _99.Location
local function update_file_with_changes(res, location)
	assert(location.marks.function_location, "function_location mark was not set, unrecoverable error")
	local mark = location.marks.function_location
	local buffer = location.buffer

	local mark_pos = vim.api.nvim_buf_get_mark(buffer, mark)
	local mark_point = Point:new(mark_pos[1], mark_pos[2] + 1)

	local ts = editor.treesitter
	local scopes = ts.function_scopes(mark_point, buffer)
	print("update_file_with_changes buffer", buffer)

	if not scopes or not scopes:has_scope() then
		Logger:error("update_file_with_changes: unable to find function at mark location")
		error("update_file_with_changes: funable to find function at mark location")
		return
	end

	local range = scopes.range[#scopes.range]

	local function_start_row, _ = range.start:to_vim()
	local function_end_row, _ = range.end_:to_vim()

	local lines = vim.split(res, "\n")
	vim.api.nvim_buf_set_lines(buffer, function_start_row, function_end_row + 1, false, lines)
end

--- @param _99 _99.State
--- @param location _99.Location
local function add_space_in_function(_99, location)
    if _99.ai_stdout_rows == 0 then
        return
    end

    local buffer = location.buffer
    local range = location.range
    local function_end_row, _ = range.end_:to_vim()

    local empty_lines = {}
    for i = 1, _99.ai_stdout_rows do
        empty_lines[i] = ""
    end

    vim.api.nvim_buf_set_lines(buffer, function_end_row, function_end_row, false, empty_lines)

    location.marks.ai_stdout_start = marks(buffer, range)
end

local function print_hello_world()
	print("Hello, World!")
end

--- @param _99 _99.State
--- @return _99.Request
local function fill_in_function(_99)
	local ts = editor.treesitter
	local cursor = Point:from_cursor()
	local scopes = ts.function_scopes(cursor)
	local scope = scopes:get_inner_scope()
	local range = scopes:get_inner_range()

	if not range or not scope then
		Logger:error("fill_in_function: unable to find any containing function")
		error("you cannot call fill_in_function not in a function")
	end

	local location = editor.Location.from_ts_node(scope, range)
	local context = Context.new(_99):finalize(_99, location)
	local request = Request.new({
		model = _99.model,
        on_stdout = function(line)
        end,
		on_complete = function(_, ok, response)
			if not ok then
				Logger:fatal("unable to fill in function, enable and check logger for more details")
			end
			update_file_with_changes(response, location)
		end,
		context = context,
	})

	context:add_to_request(request)
	location.marks.function_location = marks(location.buffer, range)
	request:add_prompt_content(_99.prompts.prompts.fill_in_function)

    add_space_in_function(_99, location)

	return request
end

return fill_in_function
