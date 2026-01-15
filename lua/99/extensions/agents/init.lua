local helpers = require("99.extensions.agents.helpers")
local M = {}

--- @class _99.Agents.Rule
--- @field name string
--- @field path string

--- @class _99.Agents.Rules
--- @field cursor _99.Agents.Rule[]
--- @field custom _99.Agents.Rule[]

--- @class _99.Agents.Agent
--- @field rules _99.Agents.Rules

---@param _99 _99.State
---@return _99.Agents.Rules
function M.rules(_99)
  local cursor = helpers.ls(_99.completion.cursor_rules)
  local custom = {}
  for _, path in ipairs(_99.completion.custom_rules or {}) do
    local custom_rule = helpers.ls(path)
    for _, c in ipairs(custom_rule) do
      table.insert(custom, c)
    end
  end
  return {
    cursor = cursor,
    custom = custom,
  }
end

--- @param rules _99.Agents.Rules
--- @return _99.Agents.Rule[]
function M.rules_to_items(rules)
  local items = {}
  for _, rule in ipairs(rules.cursor or {}) do
    table.insert(items, rule)
  end
  for _, custom_rules in ipairs(rules.custom or {}) do
    for _, rule in ipairs(custom_rules) do
      table.insert(items, rule)
    end
  end
  return items
end

return M
