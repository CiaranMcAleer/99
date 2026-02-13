-- luacheck: globals describe it assert before_each after_each
local _99 = require("99")
local test_utils = require("99.test.test_utils")
local eq = assert.are.same
local Levels = require("99.logger.level")
local Point = require("99.geo").Point
local comment_ops = require("99.ops.comment-driven")

describe("comment-driven", function()
  before_each(function()
    test_utils.clean_files()
  end)

  after_each(function()
    test_utils.clean_files()
  end)

  describe("is_comment_line", function()
    it("should detect Lua single-line comments", function()
      local is_comment, text = comment_ops.is_comment_line("-- This is a comment", "lua")
      assert.is_true(is_comment)
      eq("This is a comment", text)
    end)

    it("should detect Python single-line comments", function()
      local is_comment, text = comment_ops.is_comment_line("# This is a comment", "python")
      assert.is_true(is_comment)
      eq("This is a comment", text)
    end)

    it("should detect JavaScript/TypeScript single-line comments", function()
      local is_comment, text = comment_ops.is_comment_line("// This is a comment", "javascript")
      assert.is_true(is_comment)
      eq("This is a comment", text)
    end)

    it("should handle comments with leading whitespace", function()
      local is_comment, text = comment_ops.is_comment_line("  -- Indented comment", "lua")
      assert.is_true(is_comment)
      eq("Indented comment", text)
    end)

    it("should return false for non-comment lines", function()
      local is_comment = comment_ops.is_comment_line("local x = 1", "lua")
      assert.is_false(is_comment)
    end)
  end)

  describe("extract_comment_at_cursor", function()
    it("should extract single-line comment in Lua", function()
      local content = {
        "local function foo()",
        "  -- This is my comment",
        "  return nil",
        "end",
      }
      local buffer = test_utils.create_file(content, "lua", 2, 4)
      local cursor = Point:from_1_based(2, 4)

      local comment_text, start_row, end_row =
        comment_ops.extract_comment_at_cursor(buffer, cursor, "lua")

      eq("This is my comment", comment_text)
      eq(2, start_row)
      eq(2, end_row)
    end)

    it("should extract multi-line comment block", function()
      local content = {
        "local function bar()",
        "  -- FetchCache – Query the events database",
        "  -- for records whose title or description contain",
        "  -- the String <query> and occur within <timeframe>.",
        "  return nil",
        "end",
      }
      local buffer = test_utils.create_file(content, "lua", 3, 4)
      local cursor = Point:from_1_based(3, 4)

      local comment_text, start_row, end_row =
        comment_ops.extract_comment_at_cursor(buffer, cursor, "lua")

      local expected = table.concat({
        "FetchCache – Query the events database",
        "for records whose title or description contain",
        "the String <query> and occur within <timeframe>.",
      }, "\n")

      eq(expected, comment_text)
      eq(2, start_row)
      eq(4, end_row)
    end)

    it("should return nil when cursor is not on a comment", function()
      local content = {
        "local function baz()",
        "  return nil",
        "end",
      }
      local buffer = test_utils.create_file(content, "lua", 2, 2)
      local cursor = Point:from_1_based(2, 2)

      local comment_text = comment_ops.extract_comment_at_cursor(buffer, cursor, "lua")

      eq(nil, comment_text)
    end)

    it("should extract Python comment", function()
      local content = {
        "def foo():",
        "    # Calculate the sum of two numbers",
        "    pass",
      }
      local buffer = test_utils.create_file(content, "python", 2, 4)
      local cursor = Point:from_1_based(2, 4)

      local comment_text = comment_ops.extract_comment_at_cursor(buffer, cursor, "python")

      eq("Calculate the sum of two numbers", comment_text)
    end)
  end)

  describe("comment_driven operation", function()
    it("should generate code from comment", function()
      local content = {
        "local function test()",
        "  -- Return the string 'hello world'",
        "end",
      }
      local p = test_utils.TestProvider.new()
      _99.setup({
        provider = p,
        logger = {
          error_cache_level = Levels.ERROR,
        },
      })

      local buffer = test_utils.create_file(content, "lua", 2, 4)
      local state = _99.__get_state()
      local context = require("99.request-context").from_current_buffer(state, 100)

      local comment_driven = require("99.ops.comment-driven").comment_driven
      comment_driven(context)

      eq(1, state:active_request_count())

      -- Simulate AI response
      p:resolve("success", "  return 'hello world'")
      test_utils.next_frame()

      -- Check that code was inserted after the comment
      local result = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
      
      -- The generated code should be inserted after line 2 (the comment)
      -- Expected: blank line + generated code
      assert.is_true(#result > 3, "Buffer should have more lines")
      
      -- Check that the generated code contains our expected text
      local buffer_text = table.concat(result, "\n")
      assert.is_true(
        buffer_text:find("return 'hello world'") ~= nil,
        "Generated code should contain expected text"
      )
    end)

    it("should handle multi-line comment intent", function()
      local content = {
        "-- FetchCache – Query the database for records",
        "-- that match the given criteria",
        "",
        "local data = {}",
      }
      local p = test_utils.TestProvider.new()
      _99.setup({
        provider = p,
        logger = {
          error_cache_level = Levels.ERROR,
        },
      })

      local buffer = test_utils.create_file(content, "lua", 1, 0)
      local state = _99.__get_state()
      local context = require("99.request-context").from_current_buffer(state, 200)

      local comment_driven = require("99.ops.comment-driven").comment_driven
      comment_driven(context)

      eq(1, state:active_request_count())

      -- Simulate AI response
      local generated = table.concat({
        "function fetch_cache(criteria)",
        "  return db:query(criteria)",
        "end",
      }, "\n")
      p:resolve("success", generated)
      test_utils.next_frame()

      -- Check that code was inserted
      local result = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
      local buffer_text = table.concat(result, "\n")
      
      assert.is_true(
        buffer_text:find("function fetch_cache") ~= nil,
        "Generated code should contain function"
      )
    end)

    it("should handle cancellation", function()
      local content = {
        "-- Generate a function",
        "",
      }
      local p = test_utils.TestProvider.new()
      _99.setup({
        provider = p,
        logger = {
          error_cache_level = Levels.ERROR,
        },
      })

      local buffer = test_utils.create_file(content, "lua", 1, 0)
      local state = _99.__get_state()
      local context = require("99.request-context").from_current_buffer(state, 300)

      local comment_driven = require("99.ops.comment-driven").comment_driven
      comment_driven(context)

      _99.stop_all_requests()
      test_utils.next_frame()

      p:resolve("cancelled", "Cancelled")
      test_utils.next_frame()

      -- Buffer should remain unchanged
      local result = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
      eq(content, result)
    end)

    it("should fail gracefully when not on a comment", function()
      local content = {
        "local x = 1",
        "local y = 2",
      }
      local p = test_utils.TestProvider.new()
      _99.setup({
        provider = p,
        logger = {
          error_cache_level = Levels.FATAL,
        },
      })

      local buffer = test_utils.create_file(content, "lua", 1, 0)
      local state = _99.__get_state()
      local context = require("99.request-context").from_current_buffer(state, 400)

      local comment_driven = require("99.ops.comment-driven").comment_driven
      
      -- This should fail gracefully and not start a request
      comment_driven(context)

      -- No request should be active
      eq(0, state:active_request_count())
    end)
  end)
end)
