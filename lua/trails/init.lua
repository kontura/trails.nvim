local M = {
    root = nil,
    focused_node_key_index_start = {1, 1}, -- x,y (layer_index, node_index in layer)
    focused_node_key_index_end = {1, 1}, -- x,y (layer_index, node_index in layer)
    win = nil,
    buf = nil,
    key_to_node = {},
    layer_to_node_keys = nil,
}

local g = require("trails.graph")
local a = require("trails.ascii_graph")
local mv = require("trails.graph_move")

function M.open_split()
    M.win = vim.api.nvim_get_current_win()
    M.buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_win_set_buf(M.win, M.buf)
    vim.api.nvim_buf_set_option(M.buf, 'modifiable', false)
    vim.api.nvim_buf_set_keymap(M.buf, "n", "l", ":lua require'trails'.move_focus('l')<cr>", {silent = true})
    vim.api.nvim_buf_set_keymap(M.buf, "n", "h", ":lua require'trails'.move_focus('h')<cr>", {silent = true})
    vim.api.nvim_buf_set_keymap(M.buf, "n", "j", ":lua require'trails'.move_focus('j')<cr>", {silent = true})
    vim.api.nvim_buf_set_keymap(M.buf, "n", "k", ":lua require'trails'.move_focus('k')<cr>", {silent = true})
    vim.api.nvim_buf_set_keymap(M.buf, "n", "gd", ":lua require'trails'.jump_to_focused()<cr>", {silent = true})
end

function M.jump_to_focused()
    local focused_node_key = M.layer_to_node_keys[M.focused_node_key_index_start[1]][M.focused_node_key_index_start[2]]
    vim.lsp.util.jump_to_location(M.key_to_node[focused_node_key], "utf-8", true)
end

function M.move_focus(dir)
    local focused_node_key_start = M.layer_to_node_keys[M.focused_node_key_index_start[1]][M.focused_node_key_index_start[2]]
    local focused_node = M.key_to_node[focused_node_key_start]
    if dir == 'l' and focused_node and not focused_node.expanded then
        M.expand_node(focused_node)
    else
        local moved = mv.graph_move(M.layer_to_node_keys,
                                    M.key_to_node_with_fake,
                                    dir,
                                    M.focused_node_key_index_start,
                                    M.focused_node_key_index_end)
        M.focused_node_key_index_start = moved[1]
        M.focused_node_key_index_end = moved[2]

        local new_focused_node_key_start = M.layer_to_node_keys[M.focused_node_key_index_start[1]][M.focused_node_key_index_start[2]]
        local new_focused_node_key_end = M.layer_to_node_keys[M.focused_node_key_index_end[1]][M.focused_node_key_index_end[2]]
        M.print_lines_to_buffer(M.buf, a.draw_graph(M.key_to_node_with_fake, new_focused_node_key_start, new_focused_node_key_end, M.layer_to_node_keys))
        if vim.deep_equal(new_focused_node_key_start, new_focused_node_key_end) then
            local new_focused_node = M.key_to_node[new_focused_node_key_end]
            vim.cmd('setlocal statusline=' .. new_focused_node.uri)
        else
            vim.cmd('setlocal statusline=')
        end
    end
end

-- Called just once when the graph is first created.
-- When the user selects a root node.
local incomingCallsRoothandler = function(err, result, ctx, config)
    if result ~= nil then
        local params = vim.lsp.util.make_position_params()
        local root_name = vim.fn.expand("<cword>")
        local root = g.create_node(root_name, 12, params.textDocument.uri, "", false, {
                start = {
                        line = params.position.line,
                        character = params.position.character
                }
        }, nil, nil, g.make_key(root_name, params.textDocument.uri), {})
        M.key_to_node[root.key] = root
        for _, c_full in ipairs(result) do
            local c = c_full["from"]
            local node = g.create_node(c.name, c.kind, c.uri, c.detail, false,
                                       c.range, c_full["fromRange"],
                                       c.selectionRange, g.make_key(c.name, c.uri), {})
            node.data = c.data
            M.key_to_node[node.key] = node
            table.insert(root.children, node)
        end
        root.expanded = true
        M.root = root
    end
    M.open_split()
    M.layer_to_node_keys, M.key_to_node_with_fake = g.layout_graph(M.root, M.key_to_node)

    local first_non_empty_node_index = 1
    while (M.key_to_node_with_fake[M.layer_to_node_keys[1][first_non_empty_node_index]].type ~= g.NodeType.Regular) do
        first_non_empty_node_index = first_non_empty_node_index + 1
    end
    M.focused_node_key_index_start = {1, first_non_empty_node_index}
    M.focused_node_key_index_end = {1, first_non_empty_node_index}
    local focused_node_key = M.layer_to_node_keys[M.focused_node_key_index_start[1]][M.focused_node_key_index_start[2]]
    M.print_lines_to_buffer(M.buf, a.draw_graph(M.key_to_node_with_fake, focused_node_key, focused_node_key, M.layer_to_node_keys))
end

local handler = function(err, result, ctx, config)
    local parent = ctx.params.item
    for _, c_full in ipairs(result) do
        local c = c_full["from"]
        local node_key = g.make_key(c.name, c.uri)
        local node = M.key_to_node[node_key]
        if node == nil then
            node = g.create_node(c.name, c.kind, c.uri, c.detail, false,
                                 c.range, c_full["fromRange"],
                                 c.selectionRange, node_key, {})
            node.data = c.data
            M.key_to_node[node_key] = node
        end
        table.insert(parent.children, node)
    end
    parent.expanded = true
    local focused_node_key_start = M.layer_to_node_keys[M.focused_node_key_index_start[1]][M.focused_node_key_index_start[2]]
    M.layer_to_node_keys, M.key_to_node_with_fake = g.layout_graph(M.root, M.key_to_node)
    M.focused_node_key_index_start = g.get_key_index(M.layer_to_node_keys, focused_node_key_start)
    M.focused_node_key_index_end = M.focused_node_key_index_start
    M.print_lines_to_buffer(M.buf, a.draw_graph(M.key_to_node_with_fake, focused_node_key_start, focused_node_key_start, M.layer_to_node_keys))
end

M.setup = function(opts)
    vim.lsp.handlers['callHierarchy/incomingCalls'] = vim.lsp.with(incomingCallsRoothandler, {})
    M.namespace_id = vim.api.nvim_create_namespace('HihglightTrailsNamespace')
end

M.expand_node = function(node)
    if node.expanded then
        return
    end
    local clients = vim.lsp.get_active_clients()
    for _, client in ipairs(clients) do
        client.request('callHierarchy/incomingCalls', {item = node}, handler, 0)
    end
end

M.print_tree = function()
    --g.print_tree(M.root)
    g.print_tree(M.key_to_node_with_fake[M.layer_to_node_keys[1][1]])
end

M.print_lines_to_buffer = function(buf, lines, highlight_positions, active_node_pos, expanded_positions)
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, {})

    --local info = vim.inspect(vim.api.nvim_get_all_options_info())
    --lines = {}
    --for line in info:gmatch("([^\n]*)\n?") do
    --    table.insert(lines, line)
    --end
    vim.api.nvim_buf_set_lines(buf, 0, #lines, false, lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    for _, expanded_pos in ipairs(expanded_positions) do
        local byte_start = vim.str_byteindex(lines[expanded_pos.line], expanded_pos.start)
        vim.api.nvim_buf_set_extmark(M.buf,
                                     M.namespace_id,
                                     expanded_pos.line - 1, -- lines index from 0
                                     byte_start,
                                     {end_row = expanded_pos.line - 1, -- lines index from 0
                                      end_col = byte_start + expanded_pos.len,
                                      hl_group='Function'})
    end
    for _, active_pos in ipairs(highlight_positions) do
        local byte_start = vim.str_byteindex(lines[active_pos.line], active_pos.start)
        vim.api.nvim_buf_set_extmark(M.buf,
                                     M.namespace_id,
                                     active_pos.line - 1, -- lines index from 0
                                     byte_start,
                                     {end_row = active_pos.line - 1, -- lines index from 0
                                      end_col = byte_start + active_pos.len,
                                      hl_group='StatusLine'})
    end
    vim.api.nvim_win_set_cursor(M.win, active_node_pos)
end


return M
