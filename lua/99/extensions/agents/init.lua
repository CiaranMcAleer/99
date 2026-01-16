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
  for _, rule in ipairs(rules.custom or {}) do
    table.insert(items, rule)
  end
  return items
end

--- @param rules _99.Agents.Rules
---@param path string
---@return _99.Agents.Rule | nil
function M.get_rule_by_path(rules, path)
  for _, rule in ipairs(rules.cursor or {}) do
    if rule.path == path then
      return rule
    end
  end
  for _, rule in ipairs(rules.custom or {}) do
    if rule.path == path then
      return rule
    end
  end
  return nil
end

--- @param rules _99.Agents.Rules
---@param token string
---@return boolean
function M.is_rule(rules, token)
  for _, rule in ipairs(rules.cursor or {}) do
    if rule.path == token then
      return true
    end
  end
  for _, rule in ipairs(rules.custom or {}) do
    if rule.path == token then
      return true
    end
  end
  return false
end

--- @param rules _99.Agents.Rules
--- @param haystack string
--- @return _99.Agents.Rule[]
function M.find_rules(rules, haystack)
  --- @type _99.Agents.Rule[]
  local out = {}

  for word in haystack:gmatch("@%S+") do
    local rule_string = word:sub(2)
    local rule = M.get_rule_by_path(rules, rule_string)
    if rule then
      table.insert(out, rule)
    end
  end

  return out
end

return M
