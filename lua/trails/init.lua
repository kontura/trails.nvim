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
    vim.cmd('below split')
    M.win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_option(M.win, 'list', false)
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
    if dir == 'l' and not focused_node.expanded then
        M.expand_node(focused_node)
    else
        local get_next = function(d, index)
            if d == 'l' then
                index[1] = index[1] + 1
            elseif d == 'h' then
                index[1] = index[1] - 1
            elseif d == 'j' then
                index[2] = index[2] + 1
            elseif d == 'k' then
                index[2] = index[2] - 1
            end
        end

        local is_out_of_bounds = function(index)
            if index[1] < 1 then
                return true
            end
            if index[2] < 1 then
                return true
            end
            local layer_count = #M.layer_to_node_keys
            if index[1] > layer_count then
                return true
            end
            local count_in_layer = #M.layer_to_node_keys[index[1]]
            if index[2] > count_in_layer then
                return true
            end

            return false
        end

        local index = vim.deepcopy(M.focused_node_key_index)
        get_next(dir, index)
        if is_out_of_bounds(index) then
            return
        end
        local new_focused_node_key = M.layer_to_node_keys[index[1]][index[2]]
        local new_focused_node = M.key_to_node_with_fake[new_focused_node_key]

        while new_focused_node.type ~= g.NodeType.Regular do
            get_next(dir, index)
            if is_out_of_bounds(index) then
                return
            end
            new_focused_node_key = M.layer_to_node_keys[index[1]][index[2]]
            new_focused_node = M.key_to_node_with_fake[new_focused_node_key]
        end
        M.focused_node_key_index = index
    end

    local new_focused_node_key_start = M.layer_to_node_keys[M.focused_node_key_index_start[1]][M.focused_node_key_index_start[2]]
    local new_focused_node_key_end = M.layer_to_node_keys[M.focused_node_key_index_end[1]][M.focused_node_key_index_end[2]]
    M.print_lines_to_buffer(M.buf, a.draw_graph(M.key_to_node_with_fake, new_focused_node_key_start, new_focused_node_key_end, M.layer_to_node_keys))
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
    M.layer_to_node_keys, M.key_to_node_with_fake = g.layout_graph(M.root, M.key_to_node)
    local focused_node_key_start = M.layer_to_node_keys[M.focused_node_key_index_start[1]][M.focused_node_key_index_start[2]]
    local focused_node_key_end = M.layer_to_node_keys[M.focused_node_key_index_end[1]][M.focused_node_key_index_end[2]]
    M.print_lines_to_buffer(M.buf, a.draw_graph(M.key_to_node_with_fake, focused_node_key_start, focused_node_key_end, M.layer_to_node_keys))
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

M.print_lines_to_buffer = function(buf, lines, active_node_pos)
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, {})

    --local info = vim.inspect(vim.api.nvim_get_all_options_info())
    --lines = {}
    --for line in info:gmatch("([^\n]*)\n?") do
    --    table.insert(lines, line)
    --end
    vim.api.nvim_buf_set_lines(buf, 0, #lines, false, lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    vim.api.nvim_buf_set_extmark(M.buf,
                                 M.namespace_id,
                                 active_node_pos.line,
                                 active_node_pos.start,
                                 {end_row = active_node_pos.line,
                                  end_col = active_node_pos.start + active_node_pos.len,
                                  hl_group='Function'})
end


return M
