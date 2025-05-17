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

function return_to_win_id_before_main_menu()
    return_to_win_id(win_id_before_modal)
end

function return_to_win_id(id)
    if vim.api.nvim_win_is_valid(id) then
        vim.api.nvim_set_current_win(id)
    end
end

---
--- Create a centered floating window that is closed after 4 seconds
---

local floating_window_buffer_id = vim.api.nvim_create_buf(false, true)
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
--- Window Functions
---

-- basic_window sets a buffer as a modal
function basic_window(buffer_id, callback)
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

            if callback ~= nil then
                callback()
            end
        end
    })

end

-- search_list_callback_window will invoke the callback when an item is selected
function search_list_callback_window(title, list, callback)
    ---
    --- Config
    ---
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

    -- list
    local list_buffer_id = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(list_buffer_id, 0, -1, false, list)

    -- title buffer
    local title_buffer_id = vim.api.nvim_create_buf(false, true)
    local format_prefix = " "
    local header_content = format_prefix:rep((title_window_width - title:len()) / 2) .. title
    local file_list_header = { header_content }
    vim.api.nvim_buf_set_lines(title_buffer_id, 0, -1, false, file_list_header)

    -- empty buffer for search
    local search_buffer_id = vim.api.nvim_create_buf(false, true)

    --
    -- Windows
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
    local list_winid = vim.api.nvim_open_win(list_buffer_id, true, {
        width = list_window_width,
        height = list_window_height,
        relative = 'editor',
        row = list_starting_row,
        col = list_starting_column,
        style = 'minimal',
        border = 'solid',
    })

    -- open search window
    local search_winid = vim.api.nvim_open_win(search_buffer_id, true, {
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
        buffer = search_buffer_id,
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
    local selected_item_index = 0
    local display_ranks = {}

    vim.api.nvim_create_autocmd({ 'TextChangedI' }, {
        buffer = search_buffer_id,
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
                for index, file_path in ipairs(list) do
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
                vim.api.nvim_buf_set_lines(list_buffer_id, 0, -1, false, display_ranks)

                -- Reset the pending file select to the first file
                selected_item_index = 0
                vim.api.nvim_buf_add_highlight(list_buffer_id, 0, "LineNr", selected_item_index, 0, -1)
            else
                -- Display the normal file list when the search term is empty
                vim.api.nvim_buf_set_lines(list_buffer_id, 0, -1, false, list)
                selected_item_index = 0
                vim.api.nvim_buf_add_highlight(list_buffer_id, 0, "LineNr", selected_item_index, 0, -1)
            end

        end
    })

    -- Close the search window when hitting escape
    vim.api.nvim_buf_set_keymap(search_buffer_id, 'n', '<Esc>', ':x <CR>', {noremap = false, silent = true})
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

            -- Invoke call back with selected list item
            local selected_list_item = list[selected_item_index + 1]
            if #display_ranks > 0 then
                selected_list_item = display_ranks[selected_item_index + 1]
            end

            callback(selected_list_item)
    end

    -- 2 key mappings for enter on the search bar
    vim.api.nvim_buf_set_keymap(search_buffer_id, 'n', '<CR>', '',
        {noremap = false, silent = true,
        callback = exit_menu_and_open_file_callback,
    })
    vim.api.nvim_buf_set_keymap(search_buffer_id, 'i', '<CR>', '',
        {noremap = false, silent = true,
        callback = exit_menu_and_open_file_callback,
    })

    -- Move up and down the selection list
    local move_file_select_down = function ()
        if selected_item_index < #list - 1 then
            vim.api.nvim_buf_clear_namespace(list_buffer_id, 0, selected_item_index, selected_item_index + 1)
            selected_item_index = selected_item_index + 1
            vim.api.nvim_buf_add_highlight(list_buffer_id, 0, "LineNr", selected_item_index, 0, -1)
        end
    end
    local move_file_select_up = function ()
        if selected_item_index > 0 then
            vim.api.nvim_buf_clear_namespace(list_buffer_id, 0, selected_item_index, selected_item_index + 1)
            selected_item_index = selected_item_index - 1
            vim.api.nvim_buf_add_highlight(list_buffer_id, 0, "LineNr", selected_item_index, 0, -1)
        end
    end

    vim.api.nvim_buf_set_keymap(search_buffer_id, 'n', 'j', '', {
        noremap = false, silent = true,
        callback = move_file_select_down,
    })
    vim.api.nvim_buf_set_keymap(search_buffer_id, 'i', '<Down>', '', {
        noremap = false, silent = true,
        callback = move_file_select_down,
    })

    vim.api.nvim_buf_set_keymap(search_buffer_id, 'n', 'k', '', {
        noremap = false, silent = true,
        callback = move_file_select_up,
    })
    vim.api.nvim_buf_set_keymap(search_buffer_id, 'i', '<Up>', '', {
        noremap = false, silent = true,
        callback = move_file_select_up,
    })

    -- Enter insert mode in the search window
    vim.api.nvim_command('startinsert')

    -- Highlight the first line of the list buffer
    -- TODO: I don't think this is the correct theming API
    -- vim.api.nvim_set_hl(0, "VisualHighlight", { fg = "#ffffff", bg = "#000000" })
    vim.api.nvim_buf_add_highlight(list_buffer_id, 0, "LineNr", selected_item_index, 0, -1)
end


local main_menu_buffer_id = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(main_menu_buffer_id, 0, 4, false, {
    "",
    "b          buffer",
    "f          file",
    "j          journal",
    "t          terminal",
    "w          window",
    "q          quit",
})

main_menu = function ()
    win_id_before_modal = vim.api.nvim_get_current_win()

    basic_window(main_menu_buffer_id)
end

local window_menu_buffer_id = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(window_menu_buffer_id, 0, 4, false, {
    "",
    "/-         split",
    "d          delete",
    "",
    "h,j,k,l    move",
    "H,J,K,L    swap",
})


function window_menu()
    basic_window(window_menu_buffer_id, return_to_win_id_before_main_menu)
end

--
-- Journal
--

local journal_dir = "~/yesterdays_thoughts/"
local journal_file_ext = ".md"

local journal_menu_buffer_id = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(journal_menu_buffer_id, 0, 4, false, {
    "",
    "t          today",
    "T          tomorrow",
    "y          yesterday",
    "f          last friday",
    "s          select entry",
    "/          search",
})

function journal_menu()
    basic_window(journal_menu_buffer_id)
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
local date_string_format = "%Y.%m.%d"

function new_journal_entry_content(day_name, month_name, day_number, year_number)
    return {
        "# " .. day_name .. ", " .. month_name .. " " ..  day_number .. " " .. year_number,
        "",
        "## Tasks",
        "",
        "",
        "## Notes",
        "",
    }
end

function get_or_create_journal_entry(day_offset)
    local time_offset = os.time() - day_offset * 86400
    local file_name = os.date(date_string_format, time_offset)
    local date_info = os.date("*t", time_offset)
    local file_path = journal_dir..file_name..journal_file_ext
    local journal_buffer_id = journal_entries[file_path]
    if journal_buffer_id == nil then
        journal_buffer_id = vim.api.nvim_create_buf(false, false)
        journal_entries[file_name] = journal_buffer_id

        local day_name = days_names[date_info.wday]
        local month_name = months[date_info.month]
        local initial_content = new_journal_entry_content(day_name, month_name, date_info.day, date_info.year)
        vim.api.nvim_buf_set_lines(journal_buffer_id, 0, 0, false, initial_content)
        vim.api.nvim_buf_set_name(journal_buffer_id, file_path)

        -- Change the :w command to create or overwrite the file... ??? Can I do it?
        vim.api.nvim_create_autocmd("BufWriteCmd", {
            buffer = journal_buffer_id,
            callback = function(event)
                local file, err = io.open(vim.fn.expand(file_path), "w+")
                if file then
                    -- Your custom write logic here
                    local lines = vim.api.nvim_buf_get_lines(event.buf, 0, -1, false)
                    local content = table.concat(lines, "\n")
                    file:write(content)
                    file:close()

                    vim.notify("\""..file_path.."\" "..#lines.."L, "..#content.."B written", vim.log.levels.INFO)
                else
                    vim.notify("Error writing to file: "..err, vim.log.levels.ERROR)
                end
            end,
        })


        -- Have the initial content of the journal entry
        local previous_entry = vim.api.nvim_buf_get_lines(journal_buffer_id, 0, -1, false)
        local entry_length = #table.concat(previous_entry, "\n")

        vim.api.nvim_buf_attach(journal_buffer_id, false, {
            on_bytes = function(event_name, buffer_handle, changed_tick,
                start_row, start_column, byte_offset,
                old_end_row, old_end_column, old_end_byte_length,
                new_end_row, new_end_column, new_end_byte_length)

                print("------")
                print("event_name =", event_name)

                print("changed_tick =", changed_tick)
                print("start_row =", start_row)
                print("start_column =", start_column)
                print("byte_offset =", byte_offset)

                print("old_end_row =", old_end_row)
                print("old_end_column =", old_end_column)
                print("old_end_byte_length =", old_end_byte_length)

                print("new_end_row =", new_end_row)
                print("new_end_column =", new_end_column)
                print("new_end_byte_length =", new_end_byte_length)

                print("...")
                local line_count_difference = new_end_row - old_end_row
                print("line_count_difference =", line_count_difference)
                local byte_difference = new_end_byte_length - old_end_byte_length
                print("byte_difference =", byte_difference)

                -- TODO: known change types to handle
                --
                -- - [x] delete
                -- - [x] text
                -- - [ ] replace

                -- if byte_difference < 0 then
                if old_end_byte_length > 0 then
                    local previous_data = {}
                    for i = start_row, start_row + old_end_row do
                        print("i =", i)
                        local previous_line = previous_entry[1 + i]
                        -- trim the first line
                        if i == start_row then
                            previous_line = string.sub(previous_line, start_column, -1)
                        end

                        -- strip the last line
                        if i == start_row + old_end_row and old_end_column ~= 0 then
                            previous_line = string.sub(previous_line, 0, old_end_column + 1)
                        end

                        table.insert(previous_data, previous_line)
                    end
                    local deleted_data = table.concat(previous_data, "\n")
                    print("** deleted_data =", deleted_data)
                end

                if new_end_byte_length > 0 then
                    -- get all rows for the new data
                    local row_change_count = new_end_row
                    if new_end_row == 0 then
                         row_change_count = 1
                    end
                    -- I'm not handling this correctly, because when a new end row is a delete
                    local new_data_lines = vim.api.nvim_buf_get_lines(buffer_handle, start_row, start_row + row_change_count, true)
                    -- trim the first line.
                    new_data_lines[1] = string.sub(new_data_lines[1], start_column + 1, -1)
                    -- strip the last line even if it is the first line.
                    if new_end_column ~= 0 then
                        new_data_lines[#new_data_lines] = string.sub(new_data_lines[#new_data_lines], 0, new_end_column + 1)
                    end
                    local new_data = table.concat(new_data_lines, "\n")
                    print("** new_data =", new_data)
                end

                -- -- cusor_location is the byte index after the change
                -- local cursor_location = byte_offset

                -- update the old version of the entry for diffing after processing the changes
                previous_entry = vim.api.nvim_buf_get_lines(buffer_handle, 0, -1, false)
            end,
        })

        -- TODO: I'm not certain if I want to use this API or not
        vim.api.nvim_create_autocmd({"TextChanged", "TextChangedI"}, {
            buffer = journal_buffer_id,
            callback = function(event)
                print("------")
                -- event information
                for k, v in pairs(event) do
                    print(k.." =", v)
                end

            end
        })

    end

    -- Open set journal entry to the active buffer
    vim.api.nvim_set_current_win(win_id_before_modal)
    vim.api.nvim_win_set_buf(win_id_before_modal, journal_buffer_id)
end

function open_today()
    local journal_entry_id = get_or_create_journal_entry(0)
end

function open_tomorrow()
    local journal_entry_id = get_or_create_journal_entry(-1)
end

function open_yesterday()
    local journal_entry_id = get_or_create_journal_entry(1)
end

function open_last_friday()
    local today_info = os.date("*t")
    local last_friday_offset = math.abs(6 - today_info.wday)
    local journal_entry_id = get_or_create_journal_entry(last_friday_offset)
end

function search_select_entry_name()
    -- list of entry titles
    local entry_names = {}
    for name, buffer_id in pairs(journal_entries) do
        print(name, buffer_id)
        table.insert(entry_names, name)
    end
    -- open the entry when selected
    local callback = function(entry_name)
        local id = journal_entries[entry_name]
        if id ~= nil then
            open_journal_entry(id)
        end
    end
    -- if there are no entries, create today as an initial entry
    if #entry_names > 0 then
        search_list_callback_window("Journal", entry_names, callback)
    else
        open_today()
    end
end

function terminal_instance()
    vim.api.nvim_set_current_win(win_id_before_modal)
    vim.cmd("term")
end

-- buffer_search_list searches through the list buffers with names
--      and sets the selected buffer to the active window
function buffer_search_list()
    -- get all the vim buffers
    local buffers = vim.api.nvim_list_bufs()
    -- list the buffers with names
    local buffer_names = {}
    for i, id in ipairs(buffers) do
        local name = vim.api.nvim_buf_get_name(id)
        if #name > 0 then
            table.insert(buffer_names, name)
        end
    end
    -- search for a buffer to edit
    search_list_callback_window("Buffers", buffer_names, function(buffer_name)
        return_to_win_id_before_main_menu()
        vim.cmd("edit " .. vim.fn.fnameescape(buffer_name))
    end)
end

function git_files_window()
    -- bash command to list git files
    local output = vim.api.nvim_command_output([[!git ls-files]])
    -- Split the output into lines
    local lines = vim.split(output, "\n", true)
    table.remove(lines, 1)
    -- create a list of the file names
    local file_list = {}
    for i, value in ipairs(lines) do
        if value:len() ~= 0 then
            table.insert(file_list, value)
        end
    end
    -- search for a file to edit
    search_list_callback_window("Files", file_list, function(file_name)
        return_to_win_id_before_main_menu()
        vim.cmd("edit " .. vim.fn.fnameescape(file_name))
    end)
end

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
vim.api.nvim_buf_set_keymap(main_menu_buffer_id, "n", "t", "",
    {noremap = false, silent = true,
    callback = terminal_instance })
vim.api.nvim_buf_set_keymap(main_menu_buffer_id, "n", "b", "",
    {noremap = false, silent = true,
    callback = buffer_search_list })
vim.api.nvim_buf_set_keymap(main_menu_buffer_id, "n", "q", ":qa!<CR>",
   {noremap = false, silent = true})
-- vim.api.nvim_buf_set_keymap(main_menu_buffer_id, "n", "x", ":qa!<CR>",
--     {noremap = false, silent = true})

--
-- Journal menu keymap
--

vim.api.nvim_buf_set_keymap(journal_menu_buffer_id, "n", "t", "", {noremap = false, silent = true, callback = open_today })
vim.api.nvim_buf_set_keymap(journal_menu_buffer_id, "n", "T", "", {noremap = false, silent = true, callback = open_tomorrow })
vim.api.nvim_buf_set_keymap(journal_menu_buffer_id, "n", "y", "", {noremap = false, silent = true, callback = open_yesterday })
vim.api.nvim_buf_set_keymap(journal_menu_buffer_id, "n", "f", "", {noremap = false, silent = true, callback = open_last_friday })
vim.api.nvim_buf_set_keymap(journal_menu_buffer_id, "n", "s", "", {noremap = false, silent = true, callback = search_select_entry_name })

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

