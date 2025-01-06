-- Set up a basic configuration
vim.opt.number = true -- Show line numbers
vim.opt.relativenumber = false -- Show relative line numbers
vim.opt.tabstop = 4 -- Set tab size to 4 spaces
vim.opt.shiftwidth = 4 -- Set indent width to 4 spaces
vim.opt.expandtab = true -- Expand tabs to spaces
vim.opt.smartindent = true -- Smart indentation
vim.opt.hlsearch = true -- Highlight search matches

vim.g.mapleader = ' '
local win_id_before_modal = vim.api.nvim_get_current_win()

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
    local display_ranks = {}

    vim.api.nvim_create_autocmd({ 'TextChangedI' }, {
        buffer = git_files_search_buffer_id,
        callback = function(args)
            local line = vim.api.nvim_get_current_line()
            -- local cursor_pos = vim.api.nvim_win_get_cursor(0)
            -- local current_char = line:sub(cursor_pos[2], cursor_pos[2]) -- Get the last inserted character
            -- print("Current line: " .. line .. " | Last inserted character: " .. current_char)

            local file_path_ranks = {}

            -- When there is a search term provided
            if #line > 0 then
                -- Score every file path on the full search term everytime the search term changes
                -- TODO: this search could be improved to be incremental with the current_char
                for index, file_path in ipairs(file_list) do
                    local match_position = 1
                    -- Score the file path by using the search term to sequence through the indices ensuring the characters are present in order
                    for i = 1, #line do
                        local searched_character = line:sub(i, i)
                        local found_position = string.find(string.lower(file_path), string.lower(searched_character), match_position)

                        -- Complete the score when the match becomes invalid
                        if found_position == nil then
                            local file_rank = { index = index, file_path = file_path, match_index = found_position }
                            table.insert(file_path_ranks, file_rank)
                            break
                        end

                        match_position = found_position + 1

                        -- Complete the score when search sequence length is reached
                        if i == #line then
                            if found_position ~= nil then
                                local file_rank = { index = index, file_path = file_path, match_index = found_position }
                                table.insert(file_path_ranks, file_rank)
                            end
                        end

                    end
                end

                -- sort the file ranks
                table.sort(file_path_ranks, function(a, b)
                    if a.match_index == b.match_index then
                        return #a.file_path < #b.file_path
                    end

                    local a_match_index = a.match_index or -1 * #a.file_path
                    local b_match_index = b.match_index or -1 * #b.file_path
                    return a_match_index < b_match_index
                end)

                -- Filter the matching scored file paths to a new display list
                display_ranks  = {}
                for i, path in ipairs(file_path_ranks) do
                    if path.match_index ~= nil then
                        table.insert(display_ranks, path.file_path)
                    end
                end

                -- Update the Files selection to display the search results
                vim.api.nvim_buf_set_lines(git_files_list_buffer_id, 0, -1, false, display_ranks)

                -- Reset the pending file select to the first file
                selected_file_index = 0
                vim.api.nvim_buf_add_highlight(git_files_list_buffer_id, 0, "LineNr", selected_file_index, 0, -1)
            else
                -- Display the normal file list when the search term is empty
                vim.api.nvim_buf_set_lines(git_files_list_buffer_id, 0, -1, false, file_list)
                selected_file_index = 0
                vim.api.nvim_buf_add_highlight(git_files_list_buffer_id, 0, "LineNr", selected_file_index, 0, -1)
            end

        end
    })

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
            if vim.api.nvim_win_is_valid(win_id_before_modal) then
                vim.api.nvim_set_current_win(win_id_before_modal)
            end

            -- Open the selected file
            local selected_file_name = file_list[selected_file_index + 1]
            if #display_ranks > 0 then
                selected_file_name = display_ranks[selected_file_index + 1]
            end
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
    local move_file_select_down = function ()
        if selected_file_index < #file_list - 1 then
            vim.api.nvim_buf_clear_namespace(git_files_list_buffer_id, 0, selected_file_index, selected_file_index + 1)
            selected_file_index = selected_file_index + 1
            vim.api.nvim_buf_add_highlight(git_files_list_buffer_id, 0, "LineNr", selected_file_index, 0, -1)
        end
    end
    local move_file_select_up = function ()
        if selected_file_index > 0 then
            vim.api.nvim_buf_clear_namespace(git_files_list_buffer_id, 0, selected_file_index, selected_file_index + 1)
            selected_file_index = selected_file_index - 1
            vim.api.nvim_buf_add_highlight(git_files_list_buffer_id, 0, "LineNr", selected_file_index, 0, -1)
        end
    end

    vim.api.nvim_buf_set_keymap(git_files_search_buffer_id, 'n', 'j', '', {
        noremap = false, silent = true,
        callback = move_file_select_down,
    })
    vim.api.nvim_buf_set_keymap(git_files_search_buffer_id, 'i', '<Down>', '', {
        noremap = false, silent = true,
        callback = move_file_select_down,
    })

    vim.api.nvim_buf_set_keymap(git_files_search_buffer_id, 'n', 'k', '', {
        noremap = false, silent = true,
        callback = move_file_select_up,
    })
    vim.api.nvim_buf_set_keymap(git_files_search_buffer_id, 'i', '<Up>', '', {
        noremap = false, silent = true,
        callback = move_file_select_up,
    })

    -- Enter insert mode in the search window
    vim.api.nvim_command('startinsert')

    -- Highlight the first line of the list buffer
    -- TODO: I don't think this is the correct theming API
    -- vim.api.nvim_set_hl(0, "VisualHighlight", { fg = "#ffffff", bg = "#000000" })
    vim.api.nvim_buf_add_highlight(git_files_list_buffer_id, 0, "LineNr", selected_file_index, 0, -1)

end


vim.api.nvim_create_user_command('GitFiles', git_files_window, {})

function basic_window(buffer_id, previous_window_id)
    -- center horizontally
    local editor_width = vim.api.nvim_get_option_value('columns', {})
    local floating_window_width = 50
    local starting_column = (editor_width - floating_window_width) / 2

    -- center verticially
    local editor_height = vim.api.nvim_get_option_value('lines', {})
    local floating_window_height = 10
    local starting_row = (editor_height - floating_window_height) / 2

    -- open new centered window
    local winid = vim.api.nvim_open_win(buffer_id, true, {
        width = floating_window_width,
        height = floating_window_height,
        relative = 'editor',
        row = starting_row,
        col = starting_column,
        style = 'minimal',
        border = 'solid',
    })

    -- Close the window with hitting escape
    vim.api.nvim_buf_set_keymap(buffer_id, 'n', '<Esc>', ':x <CR>', {noremap = true, silent = true})

    -- Close the modal window when the focus leaves the window
    -- Return the cursor focus to the original location before the modal was activated if provided
    vim.api.nvim_create_autocmd({ 'BufLeave', 'BufWinLeave' }, {
        buffer = buffer_id,
        callback = function()
            if vim.api.nvim_win_is_valid(winid) then
                vim.api.nvim_win_close(winid, true)
            end

            if vim.api.nvim_win_is_valid(previous_window_id) then
                vim.api.nvim_set_current_win(previous_window_id)
            end
        end
    })

end

local main_menu_buffer_id = vim.api.nvim_create_buf(true, true)
vim.api.nvim_buf_set_lines(main_menu_buffer_id, 0, 4, false, {
    "",
    "w          window",
    "f          file",
    "j          journal"
})

main_menu = function ()
    win_id_before_modal = vim.api.nvim_get_current_win()

    basic_window(main_menu_buffer_id, -1)
end

local window_menu_buffer_id = vim.api.nvim_create_buf(true, true)
vim.api.nvim_buf_set_lines(window_menu_buffer_id, 0, 4, false, {
    "",
    "/-         split",
    "d          delete",
    "",
    "h,j,k,l    move",
    "H,J,K,L    swap",
})


function window_menu()
    basic_window(window_menu_buffer_id, win_id_before_modal)
end

--
-- Journal
--

local journal_menu_buffer_id = vim.api.nvim_create_buf(true, true)
vim.api.nvim_buf_set_lines(journal_menu_buffer_id, 0, 4, false, {
    "",
    "t          today",
    "y          yesterday",
    "f          last friday",
    "s          search",
    "d          select date"
})

function journal_menu()
    basic_window(journal_menu_buffer_id, win_id_before_modal)
end

local journal_entries = {}
local days_names = {
    "Sunday",
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday"
}
local months = {
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December"
}

function open_today()
    local todays_date = os.date("%Y.%m.%d")
    local journal_buffer_id = journal_entries[todays_date]
    if journal_buffer_id == nil then
        journal_buffer_id = vim.api.nvim_create_buf(false, true)
        journal_entries[todays_date] = journal_buffer_id

        local date = os.date("*t")
        local day_name = days_names[date.wday]
        local month_name = months[date.month]
        vim.api.nvim_buf_set_lines(journal_buffer_id, 0, 0, false, {
            "# " .. day_name .. ", " .. month_name .. " " ..  date.day .. " " .. date.year,
            "",
            "## Tasks",
            "",
            "## Notes",
        })
    end

    vim.api.nvim_set_current_win(win_id_before_modal)
    vim.api.nvim_win_set_buf(win_id_before_modal, journal_buffer_id)
end

vim.api.nvim_buf_set_keymap(journal_menu_buffer_id, "n", "t", "", {noremap = false, silent = true, callback = open_today })


-- Main menu keymap
vim.keymap.set("n", "<leader>", main_menu, { noremap = true, silent = true })
vim.api.nvim_buf_set_keymap(main_menu_buffer_id, "n", "f", "",
    {noremap = false, silent = true,
    callback = git_files_window })
vim.api.nvim_buf_set_keymap(main_menu_buffer_id, "n", "w", "",
    {noremap = false, silent = true,
    callback = window_menu })
vim.api.nvim_buf_set_keymap(main_menu_buffer_id, "n", "j", "",
    {noremap = false, silent = true,
    callback = journal_menu })

--
-- Window menu keymap
--

-- window tiling
vim.api.nvim_buf_set_keymap(window_menu_buffer_id, "n", "/", ":x<CR>:vs<CR>", {noremap = false, silent = true})
vim.api.nvim_buf_set_keymap(window_menu_buffer_id, "n", "-", ":x<CR>:sp<CR>", {noremap = false, silent = true})
vim.api.nvim_buf_set_keymap(window_menu_buffer_id, "n", "d", ":x<CR>:x<CR>", {noremap = false, silent = true})

-- window focus
vim.api.nvim_buf_set_keymap(window_menu_buffer_id, "n", "h", ":x<CR><C-w>h", {noremap = false, silent = true})
vim.api.nvim_buf_set_keymap(window_menu_buffer_id, "n", "j", ":x<CR><C-w>j", {noremap = false, silent = true})
vim.api.nvim_buf_set_keymap(window_menu_buffer_id, "n", "k", ":x<CR><C-w>k", {noremap = false, silent = true})
vim.api.nvim_buf_set_keymap(window_menu_buffer_id, "n", "l", ":x<CR><C-w>l", {noremap = false, silent = true})

-- window swap
vim.api.nvim_buf_set_keymap(window_menu_buffer_id, "n", "H", ":x<CR><C-w>H", {noremap = false, silent = true})
vim.api.nvim_buf_set_keymap(window_menu_buffer_id, "n", "J", ":x<CR><C-w>J", {noremap = false, silent = true})
vim.api.nvim_buf_set_keymap(window_menu_buffer_id, "n", "K", ":x<CR><C-w>K", {noremap = false, silent = true})
vim.api.nvim_buf_set_keymap(window_menu_buffer_id, "n", "L", ":x<CR><C-w>L", {noremap = false, silent = true})

