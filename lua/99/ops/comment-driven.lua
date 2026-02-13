local Request = require("99.request")
local RequestStatus = require("99.ops.request_status")
local Mark = require("99.ops.marks")
local geo = require("99.geo")
local make_clean_up = require("99.ops.clean-up")
local Completions = require("99.extensions.completions")

local Point = geo.Point

--- Language-specific comment patterns
--- Each language can have single-line and multi-line comment styles
local COMMENT_PATTERNS = {
  lua = { single = "^%s*%-%-+%s*(.*)$" },
  python = { single = "^%s*#+%s*(.*)$" },
  javascript = { single = "^%s*//+%s*(.*)$", multi_start = "^%s*/%*", multi_end = "%*/$" },
  typescript = { single = "^%s*//+%s*(.*)$", multi_start = "^%s*/%*", multi_end = "%*/$" },
  go = { single = "^%s*//+%s*(.*)$", multi_start = "^%s*/%*", multi_end = "%*/$" },
  java = { single = "^%s*//+%s*(.*)$", multi_start = "^%s*/%*", multi_end = "%*/$" },
  cpp = { single = "^%s*//+%s*(.*)$", multi_start = "^%s*/%*", multi_end = "%*/$" },
  ruby = { single = "^%s*#+%s*(.*)$" },
  elixir = { single = "^%s*#+%s*(.*)$" },
}

--- Check if a line is a comment based on file type
--- @param line string
--- @param file_type string
--- @return boolean, string? -- is_comment, extracted_text
local function is_comment_line(line, file_type)
  local patterns = COMMENT_PATTERNS[file_type]
  if not patterns then
    return false, nil
  end

  -- Check single-line comment
  if patterns.single then
    local text = line:match(patterns.single)
    if text then
      return true, text
    end
  end

  -- Check multi-line comment start (for now, treat as single line)
  if patterns.multi_start and line:match(patterns.multi_start) then
    return true, line
  end

  return false, nil
end

--- Extract comment text at or near the cursor position
--- Supports multi-line comments by collecting consecutive comment lines
--- @param buffer number
--- @param cursor _99.Point
--- @param file_type string
--- @return string?, number?, number? -- comment_text, start_row, end_row (1-based)
local function extract_comment_at_cursor(buffer, cursor, file_type)
  local total_lines = vim.api.nvim_buf_line_count(buffer)
  local cursor_row = cursor.row -- 1-based

  -- Check if current line is a comment
  local current_line = vim.api.nvim_buf_get_lines(buffer, cursor_row - 1, cursor_row, false)[1]
  local is_comment, _ = is_comment_line(current_line, file_type)

  if not is_comment then
    return nil, nil, nil
  end

  -- Find the start of the comment block (scan upwards)
  local start_row = cursor_row
  while start_row > 1 do
    local prev_line = vim.api.nvim_buf_get_lines(buffer, start_row - 2, start_row - 1, false)[1]
    local prev_is_comment, _ = is_comment_line(prev_line, file_type)
    if not prev_is_comment then
      break
    end
    start_row = start_row - 1
  end

  -- Find the end of the comment block (scan downwards)
  local end_row = cursor_row
  while end_row < total_lines do
    local next_line = vim.api.nvim_buf_get_lines(buffer, end_row, end_row + 1, false)[1]
    local next_is_comment, _ = is_comment_line(next_line, file_type)
    if not next_is_comment then
      break
    end
    end_row = end_row + 1
  end

  -- Extract and clean comment text
  local comment_lines = vim.api.nvim_buf_get_lines(buffer, start_row - 1, end_row, false)
  local cleaned_lines = {}

  for _, line in ipairs(comment_lines) do
    local _, text = is_comment_line(line, file_type)
    if text then
      table.insert(cleaned_lines, text)
    end
  end

  local comment_text = table.concat(cleaned_lines, "\n")
  return comment_text, start_row, end_row
end

--- Get the full buffer contents as text
--- @param buffer number
--- @return string
local function get_file_contents(buffer)
  local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
  return table.concat(lines, "\n")
end

--- Build a prompt for comment-driven code generation
--- @param comment_text string
--- @param context _99.RequestContext
--- @param start_row number
--- @param end_row number
--- @return string
local function build_comment_prompt(comment_text, context, start_row, end_row)
  return string.format(
    [[
You receive a comment in neovim that describes what code to implement.
The comment contains the user's intent and requirements.
Generate code that implements the described behavior.

<COMMENT_LOCATION>
File: %s
Lines: %d-%d
</COMMENT_LOCATION>

<USER_INTENT>
%s
</USER_INTENT>

<FILE_CONTEXT>
%s
</FILE_CONTEXT>

<INSTRUCTIONS>
- Generate only the code implementation, no explanations
- Follow the style and conventions of the existing file
- Place the code appropriately based on the comment location
- If the comment is inside a function, generate the function body
- If the comment is at the top level, generate a complete function or class
- Do not include the comment itself in the output
</INSTRUCTIONS>
]],
    context.full_path,
    start_row,
    end_row,
    comment_text,
    get_file_contents(context.buffer)
  )
end

--- Main entry point for comment-driven code generation
--- @param context _99.RequestContext
--- @param opts? _99.ops.Opts
local function comment_driven(context, opts)
  opts = opts or {}
  local logger = context.logger:set_area("comment_driven")
  local cursor = Point:from_cursor()

  -- Extract comment at cursor
  local comment_text, start_row, end_row =
    extract_comment_at_cursor(context.buffer, cursor, context.file_type)

  if not comment_text then
    logger:fatal(
      "No AI intent comment found at cursor position. Please place your cursor on or near a comment describing what you want to implement."
    )
    return
  end

  logger:debug(
    "Found comment",
    "text",
    comment_text,
    "start_row",
    start_row,
    "end_row",
    end_row
  )

  -- Create request and marks
  local request = Request.new(context)

  -- Mark the position where we'll insert the generated code
  -- We'll insert below the comment block
  local insertion_point = Point:from_1_based(end_row, 1)
  local insertion_mark = Mark.mark_point(context.buffer, insertion_point)
  context.marks.insertion_mark = insertion_mark

  -- Create status indicators
  local display_ai_status = context._99.ai_stdout_rows > 1
  local status = RequestStatus.new(
    250,
    context._99.ai_stdout_rows or 1,
    "Generating from comment",
    insertion_mark
  )

  local clean_up = make_clean_up(context, "CommentDriven", function()
    status:stop()
    context:clear_marks()
    request:cancel()
  end)

  -- Build the prompt
  local full_prompt = build_comment_prompt(comment_text, context, start_row, end_row)

  -- Handle additional prompt if provided
  local additional_prompt = opts.additional_prompt
  if additional_prompt then
    full_prompt = context._99.prompts.prompts.prompt(additional_prompt, full_prompt)

    local refs = Completions.parse(additional_prompt)
    context:add_references(refs)
  end

  -- Handle additional rules
  local additional_rules = opts.additional_rules
  if additional_rules then
    context:add_agent_rules(additional_rules)
  end

  request:add_prompt_content(full_prompt)
  status:start()

  request:start({
    on_complete = function(status_result, response)
      vim.schedule(clean_up)
      if status_result == "cancelled" then
        logger:debug("request cancelled for comment-driven generation")
      elseif status_result == "failed" then
        logger:error(
          "request failed for comment-driven generation",
          "error response",
          response or "no response provided"
        )
      elseif status_result == "success" then
        local valid = insertion_mark:is_valid()
        if not valid then
          logger:fatal("insertion mark is no longer valid")
          return
        end

        -- Insert the generated code below the comment
        local point = Point.from_mark(insertion_mark)
        local insert_row = point.row - 1 -- Convert to 0-based for nvim API

        -- Split response into lines and insert
        local lines = vim.split(response, "\n")

        -- Insert a blank line first, then the code
        table.insert(lines, 1, "")

        vim.api.nvim_buf_set_lines(context.buffer, insert_row, insert_row, false, lines)

        logger:debug("Inserted generated code", "row", insert_row, "lines", #lines)
      end
    end,
    on_stdout = function(line)
      if display_ai_status then
        status:push(line)
      end
    end,
    on_stderr = function(line)
      logger:debug("comment_driven#on_stderr received", "line", line)
    end,
  })
end

return {
  comment_driven = comment_driven,
  extract_comment_at_cursor = extract_comment_at_cursor,
  is_comment_line = is_comment_line,
}
