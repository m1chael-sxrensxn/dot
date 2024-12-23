-- Set up a basic configuration
vim.opt.number = true -- Show line numbers
vim.opt.relativenumber = false -- Show relative line numbers
vim.opt.tabstop = 4 -- Set tab size to 4 spaces
vim.opt.shiftwidth = 4 -- Set indent width to 4 spaces
vim.opt.expandtab = true -- Expand tabs to spaces
vim.opt.smartindent = true -- Smart indentation
vim.opt.hlsearch = true -- Highlight search matches

vim.g.mapleader = ' '

---
--- Create a centered floating window that is closed after 4 seconds
---

local floating_window_buffer_id = vim.api.nvim_create_buf(true, true)
vim.api.nvim_buf_set_lines(floating_window_buffer_id, 0, 4, false, {"a", "b", "c"})

floating_window = function ()
    -- center horizontally
    local editor_width = vim.api.nvim_get_option_value('columns', {})
    local floating_window_width = 50
    local starting_column = (editor_width - floating_window_width) / 2

    -- center verticially
    local editor_height = vim.api.nvim_get_option_value('lines', {})
    local floating_window_height = 10
    local starting_row = (editor_height - floating_window_height) / 2

    -- open new centered window
    local winid = vim.api.nvim_open_win(floating_window_buffer_id, false, {
        width = floating_window_width,
        height = floating_window_height,
        relative = 'editor',
        row = starting_row,
        col = starting_column,
        style = 'minimal',
        border = 'single',
    })

    -- close after 4 seconds
    vim.defer_fn(function()
        vim.api.nvim_win_close(winid, true)
    end,4000)

    -- focus window
    vim.api.nvim_set_current_win(winid)

end

vim.api.nvim_create_user_command("FloatingWindow", floating_window, {})


