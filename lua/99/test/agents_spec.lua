-- luacheck: globals describe it assert
local Agents = require("99.extensions.agents")
local eq = assert.are.same

local function c(t, item)
  return vim.tbl_contains(t, function(v)
    return vim.deep_equal(v, item)
  end, { predicate = true })
end

local function a(p)
  return vim.fs.joinpath(vim.uv.cwd(), p)
end

local cursor_mds = {
  { name = "database", path = a("scratch/cursor/rules/database.mdc") },
  { name = "my-proj", path = a("scratch/cursor/rules/my-proj.mdc") },
}
local custom_mds = {
  { name = "back-end", path = a("scratch/custom_rules/back-end.md") },
  { name = "foo", path = a("scratch/custom_rules/foo.md") },
  { name = "front-end", path = a("scratch/custom_rules/front-end.md") },
  { name = "vim.lsp", path = a("scratch/custom_rules/vim.lsp.md") },
  { name = "vim", path = a("scratch/custom_rules/vim.md") },
  {
    name = "vim.treesitter",
    path = a("scratch/custom_rules/vim.treesitter.md"),
  },
}

--- @return _99.State
local function r(cursor, custom)
  return {
    completion = {
      cursor_rules = cursor,
      custom_rules = { custom },
    },
  }
end

--- @param rules _99.Agents.Rules
local function test_cursor(rules)
  for _, cursor in ipairs(cursor_mds) do
    eq(true, c(rules.cursor, cursor))
    eq(false, c(rules.custom, cursor))
  end
end

--- @param rules _99.Agents.Rules
local function test_custom(rules)
  for _, custom in ipairs(custom_mds) do
    eq(true, c(rules.custom, custom))
    eq(false, c(rules.cursor, custom))
  end
end
describe("99.agents.helpers", function()
  it("should generate rules from _99 state with completion rules", function()
    local _99 = r("scratch/cursor/rules", "scratch/custom_rules/")
    local rules = Agents.rules(_99)
    test_cursor(rules)
    test_custom(rules)
  end)

  it("generate without cursor", function()
    local _99 = r("foo/bar/bazz", "scratch/custom_rules/")
    local rules = Agents.rules(_99)
    test_custom(rules)
  end)

  it("generate without custom", function()
    local _99 = r("scratch/cursor/rules")
    local rules = Agents.rules(_99)
    test_cursor(rules)
  end)
end)
