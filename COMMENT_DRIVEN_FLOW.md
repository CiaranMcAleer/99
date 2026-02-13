# Comment-Driven Code Generation Example

This example demonstrates the new comment-driven flow for the 99 AI agent plugin.

## Example 1: Lua Function

```lua
-- FetchCache – Query the events database for records whose `title` or `description` 
-- contain the String <query> and occur within <timeframe>. Return a JSON-serializable 
-- list of event objects with id, title, start_time, end_time.
```

Place your cursor on or near this comment and run `:lua require('99').comment()` or `:lua require('99').visual()` 
(visual will auto-detect the comment). The AI will generate the function implementation.

## Example 2: Python Function

```python
# Calculate the Fibonacci sequence up to n terms
# Return a list of numbers
```

## Example 3: JavaScript Function

```javascript
// validateEmail - Check if a string is a valid email address
// Returns true if valid, false otherwise
// Handle edge cases like empty strings and null values
```

## Usage

There are two ways to use the comment-driven flow:

### 1. Automatic Detection in Visual Mode

Place your cursor on a comment and run the visual command:

```vim
" In your config
vim.keymap.set("v", "<leader>9v", function()
    require("99").visual()
end)
```

When your cursor is on a comment, it will automatically use comment-driven generation instead of visual selection.

### 2. Explicit Comment Command

Use the new dedicated comment command:

```vim
" Add to your config
vim.keymap.set("n", "<leader>9c", function()
    require("99").comment()
end)
```

Place your cursor on or near a comment describing what you want, then trigger the command.

## Features

- **Async Operation**: Like all 99 operations, comment-driven generation runs asynchronously without blocking your editor
- **Multi-line Comments**: Supports multi-line comment blocks - the AI will read the entire block
- **Language Support**: Works with Lua, Python, JavaScript, TypeScript, Go, Java, C++, Ruby, and Elixir
- **Context Aware**: Sends the entire file context to help the AI understand where to place the code
- **Existing Flow Preserved**: The original function/Params and visual selection flows still work

## How It Works

1. **Comment Detection**: The plugin detects if your cursor is on a comment line
2. **Comment Extraction**: Extracts the full comment block (handles multi-line comments)
3. **Prompt Building**: Creates a structured prompt with the comment as user intent and file context
4. **Async Generation**: Sends the request through the same async pipeline used by other 99 operations
5. **Code Insertion**: Inserts the generated code below the comment block

## Benefits

- **Simpler Workflow**: Just write a comment describing what you want
- **Intent-Rich**: Comments can be detailed and descriptive
- **Natural**: Feels like pair programming with an AI
- **Non-Blocking**: Continue editing while AI works in the background
