local Range = require("99.geo").Range

--- @class _99.Location
--- @field full_path string
--- @field range Range
--- @field node TSNode
--- @field buffer number
--- @field marks table<string, string>
local Location = {}
Location.__index = Location

function Location.from_range(range)
    local full_path = vim.api.nvim_buf_get_name(range.buffer)

    return setmetatable({
        buffer = range.buffer,
        full_path = full_path,
        range = range,
        marks = {}
    }, Location)
end

--- @param node TSNode
--- @param range Range
function Location.from_ts_node(node, range)
    local full_path = vim.api.nvim_buf_get_name(range.buffer)

    return setmetatable({
        buffer = range.buffer,
        full_path = full_path,
        range = range,
        node = node,
        marks = {}
    }, Location)
end

return Location
