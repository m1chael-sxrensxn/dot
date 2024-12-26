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
vim.api.nvim_buf_set_lines(floating_window_buffer_id, 0, 4, false, {"today", "yesterday", "last friday"})
vim.api.nvim_buf_set_keymap(floating_window_buffer_id, "n", "a", ":echo 'picked a' <CR>", { noremap = true, silent = true })
vim.api.nvim_buf_set_keymap(floating_window_buffer_id, "n", "b", ":echo 'picked b' <CR>", { noremap = true, silent = true })

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
    local winid = vim.api.nvim_open_win(floating_window_buffer_id, true, {
        width = floating_window_width,
        height = floating_window_height,
        relative = 'editor',
        row = starting_row,
        col = starting_column,
        style = 'minimal',
        border = 'solid',
    })

    -- Close the window with hitting escape
    vim.api.nvim_buf_set_keymap(floating_window_buffer_id, 'n', '<Esc>', ':x <CR>', {noremap = true, silent = true})

    -- close after 4 seconds
    vim.defer_fn(function()
        if vim.api.nvim_win_is_valid(winid) then
            vim.api.nvim_win_close(winid, true)
        end
    end,4000)


    -- What am I interested in now that I have a window?
    --
    -- filtering text with a select? buffers, files, etc
    -- can I use all input into the buffer or window and intercept it to make changes to the buffer?

end

vim.api.nvim_create_user_command("FloatingWindow", floating_window, {})

---
--- Attempt to make a git file filter menu for vim
---


function git_files_window()
    -- window heights
    local search_window_height = 1
    local title_window_height = 1
    local list_window_height = 20

    -- window widths
    local search_window_width = 50
    local title_window_width = 50
    local list_window_width = 50

    ---
    --- Buffers
    ---

    -- git files list buffer
    local git_files_list_buffer_id = vim.api.nvim_create_buf(false, true)
    -- Get the command output
    local output = vim.api.nvim_command_output([[!git ls-files]])
    -- Split the output into lines
    local lines = vim.split(output, "\n", true)
    table.remove(lines, 1)
    local file_list = {}

    for i, value in ipairs(lines) do
        if value:len() ~= 0 then
            table.insert(file_list, value)
        end
    end

    -- Insert the output into the buffer
    vim.api.nvim_buf_set_lines(git_files_list_buffer_id, 0, -1, false, file_list)

    -- title buffer
    local title_buffer_id = vim.api.nvim_create_buf(false, true)
    local format_prefix = " "
    local title_text = "Git Files"
    local header_content = format_prefix:rep((title_window_width - title_text:len()) / 2) .. title_text
    local file_list_header = { header_content }
    vim.api.nvim_buf_set_lines(title_buffer_id, 0, -1, false, file_list_header)

    -- empty buffer for search
    local git_files_search_buffer_id = vim.api.nvim_create_buf(false, true)

    --
    -- Create windows
    --
    local editor_width = vim.api.nvim_get_option_value('columns', {})
    local editor_height = vim.api.nvim_get_option_value('lines', {})

    -- title window
    local title_starting_column = (editor_width - title_window_width) / 2
    local title_starting_row = (editor_height - search_window_height - list_window_height - 7) / 2

    -- search window
    local search_starting_column = (editor_width - search_window_width) / 2
    local search_starting_row = title_starting_row + 2

    -- list window
    local list_starting_column = (editor_width - list_window_width) / 2
    local list_starting_row = search_starting_row + 3

    -- open title window
    local title_winid = vim.api.nvim_open_win(title_buffer_id, true, {
        width = title_window_width,
        height = title_window_height,
        relative = 'editor',
        row = title_starting_row,
        col = title_starting_column,
        style = 'minimal',
        border = 'solid',
    })

    -- open files list window
    local list_winid = vim.api.nvim_open_win(git_files_list_buffer_id, true, {
        width = list_window_width,
        height = list_window_height,
        relative = 'editor',
        row = list_starting_row,
        col = list_starting_column,
        style = 'minimal',
        border = 'solid',
    })

    -- open search window
    local search_winid = vim.api.nvim_open_win(git_files_search_buffer_id, true, {
        width = search_window_width,
        height = search_window_height,
        relative = 'editor',
        row = search_starting_row,
        col = search_starting_column,
        style = 'minimal',
        border = 'solid',
    })

    -- close file list window when leaving the search window
    vim.api.nvim_create_autocmd({ 'BufLeave', 'BufWinLeave' }, {
        buffer = git_files_search_buffer_id,
        callback = function()
            if vim.api.nvim_win_is_valid(search_winid) then
                vim.api.nvim_win_close(search_winid, true)
            end
            if vim.api.nvim_win_is_valid(title_winid) then
                vim.api.nvim_win_close(title_winid, true)
            end
            if vim.api.nvim_win_is_valid(list_winid) then
                vim.api.nvim_win_close(list_winid, true)
            end
        end
    })
    local selected_file_index = 0

    -- Close the search window when hitting escape
    vim.api.nvim_buf_set_keymap(git_files_search_buffer_id, 'n', '<Esc>', ':x <CR>', {noremap = false, silent = true})
    -- When enter is hit on the search bar
    local exit_menu_and_open_file_callback = function ()
            -- Close file menu
            if vim.api.nvim_win_is_valid(search_winid) then
                vim.api.nvim_win_close(search_winid, true)
            end
            if vim.api.nvim_win_is_valid(title_winid) then
                vim.api.nvim_win_close(title_winid, true)
            end
            if vim.api.nvim_win_is_valid(list_winid) then
                vim.api.nvim_win_close(list_winid, true)
            end

            -- Return to command mode from menu
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
            -- Open the selected file
            local selected_file_name = file_list[selected_file_index + 1]
            vim.cmd("edit " .. vim.fn.fnameescape(selected_file_name))
    end

    -- 2 key mappings for enter on the search bar
    vim.api.nvim_buf_set_keymap(git_files_search_buffer_id, 'n', '<CR>', '',
        {noremap = false, silent = true,
        callback = exit_menu_and_open_file_callback,
    })
    vim.api.nvim_buf_set_keymap(git_files_search_buffer_id, 'i', '<CR>', '',
        {noremap = false, silent = true,
        callback = exit_menu_and_open_file_callback,
    })

    -- Move up and down the selection list
    vim.api.nvim_buf_set_keymap(git_files_search_buffer_id, 'n', 'j', '', {
        noremap = false, silent = true,
        callback = function ()
            if selected_file_index < #file_list - 1 then
                vim.api.nvim_buf_clear_namespace(git_files_list_buffer_id, 0, selected_file_index, selected_file_index + 1)
                selected_file_index = selected_file_index + 1
                vim.api.nvim_buf_add_highlight(git_files_list_buffer_id, 0, "LineNr", selected_file_index, 0, -1)
            end
        end
    })
    vim.api.nvim_buf_set_keymap(git_files_search_buffer_id, 'n', 'k', '', {
        noremap = false, silent = true,
        callback = function ()
            if selected_file_index > 0 then
                vim.api.nvim_buf_clear_namespace(git_files_list_buffer_id, 0, selected_file_index, selected_file_index + 1)
                selected_file_index = selected_file_index - 1
                vim.api.nvim_buf_add_highlight(git_files_list_buffer_id, 0, "LineNr", selected_file_index, 0, -1)
            end
        end
    })

    -- Enter insert mode in the search window
    vim.api.nvim_command('startinsert')

    -- Highlight the first line of the list buffer
    -- TODO: I don't think this is the correct theming API
    -- vim.api.nvim_set_hl(0, "VisualHighlight", { fg = "#ffffff", bg = "#000000" })
    vim.api.nvim_buf_add_highlight(git_files_list_buffer_id, 0, "LineNr", selected_file_index, 0, -1)

end


vim.api.nvim_create_user_command('GitFiles', git_files_window, {})


