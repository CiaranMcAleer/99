R("99")
local _99 = require("99")
_99.setup({
  completion = {
    custom_rules = {
      "~/.behaviors/",
    },
    source = "cmp",
  },
})
local Ext = require("99.extensions")
local Agents = require("99.extensions.agents")
local Helpers = require("99.extensions.agents.helpers")

print(vim.inspect(Agents.rules(_99.__get_state())))
print(vim.inspect(Helpers.ls("/home/theprimeagen/.behaviors")))

--- @class Config
--- @field width number
--- @field height number
--- @field offset_row number
--- @field offset_col number
--- @field border string
function create_window(config)
  -- Create a new buffer
  local buf = vim.api.nvim_create_buf(false, true)

  -- Configure the floating window
  local win_config = {
    relative = 'editor',
    width = config.width,
    height = config.height,
    row = config.offset_row,
    col = config.offset_col,
    style = 'minimal',
    border = 'rounded'
  }

  -- Open the floating window
  local win = vim.api.nvim_open_win(buf, true, win_config)

  return { buf = buf, win = win }
end
