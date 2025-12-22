--- @class _99.window.Module
--- @field active_windows _99.window.Window[]
local M = {
    active_windows = {}
}
local nsid = vim.api.nvim_create_namespace("99.window.error")

--- @class _99.window.Config
--- @field width number
--- @field height number
--- @field anchor "NE"

--- @class _99.window.Window
--- @field config _99.window.Config
--- @field win_id number
--- @field buf_id number

--- @return number
--- @return number
local function get_ui_dimensions()
    local ui = vim.api.nvim_list_uis()[1]
    return ui.width, ui.height
end

--- @return _99.window.Config
local function create_window_config()
    local width, _ = get_ui_dimensions()
    return {
        width = width - 2,
        height = 3,
        anchor = "NE",
    }
end

--- @return _99.window.Window
local function create_floating_window()
    local config = create_window_config()
    local buf_id = vim.api.nvim_create_buf(false, true)
    local win_id = vim.api.nvim_open_win(buf_id, true, {
        relative = "editor",
        width = config.width,
        height = config.height,
        col = 0,
        row = 0,
        anchor = config.anchor,
        style = "minimal",
    })

    return {
        config = config,
        win_id = win_id,
        buf_id = buf_id,
    }
end

--- @param window _99.window.Window
local function highlight_error(window)
    local line_count = vim.api.nvim_buf_line_count(window.buf_id)

    if line_count > 0 then
        vim.api.nvim_buf_set_extmark(window.buf_id, nsid, 0, 0, {
            end_row = 1,
            hl_group = "Normal",
            hl_eol = true,
        })
    end

    if line_count > 1 then
        vim.api.nvim_buf_set_extmark(window.buf_id, nsid, 1, 0, {
            end_row = line_count,
            hl_group = "ErrorMsg",
            hl_eol = true,
        })
    end
end

--- @param error_text string
--- @return _99.window.Window
function M.display_error(error_text)
    local window = create_floating_window()
    table.insert(M.active_windows, window)

    local lines = vim.split(error_text, "\n")
    table.insert(lines, 1, "")
    table.insert(lines, 1, "99: Fatal operational error encountered (error logs may have more in-depth information)")

    vim.api.nvim_buf_set_lines(window.buf_id, 0, -1, false, lines)
    highlight_error(window)
    return window
end

function M.clear_active_popups()
    for _, window in ipairs(M.active_windows) do
        if vim.api.nvim_win_is_valid(window.win_id) then
            vim.api.nvim_win_close(window.win_id, true)
        end
        if vim.api.nvim_buf_is_valid(window.buf_id) then
            vim.api.nvim_buf_delete(window.buf_id, { force = true })
        end
    end
    M.active_windows = {}
end

return M
