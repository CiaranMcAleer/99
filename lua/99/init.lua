local Logger = require("99.logger.logger")
local editor = require("99.editor")
local geo = require("99.geo")
local Point = geo.Point

--- @class LoggerOptions
--- @field level number?
--- @field path string?

--- @class _99Options
--- @field logger LoggerOptions?

--- @class _99
local _99 = {}
_99.__index = _99

function _99.fill_in_function()
	local ts = editor.treesitter
	local cursor = Point:from_cursor()
	local scopes = ts.function_scopes(cursor)

	if scopes == nil or #scopes.range == 0 then
		Logger:warn("fill_in_function: unable to find any containing function")
		error("you cannot call fill_in_function not in a function")
	end

	local range = scopes.range[#scopes.range]
	local open_code_query = {
		range:to_text(),
	}
end

--- @param opts _99Options?
function _99.init(opts)
	opts = opts or {}
	local logger = opts.logger
	if logger then
		if logger.level then
			Logger:set_level(logger.level)
		end
		if logger.path then
			Logger:file_sink(logger.path)
		end
	end
end

_99.fill_in_function()

return _99
