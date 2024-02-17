local M = {
    root = nil,
    focused_node_key_index = {1, 1}, -- x,y (layer_index, node_index in layer)
    win = nil,
    buf = nil,
    key_to_node = {},
    layer_to_node_keys = nil,
    layer_widht = nil
}

local g = require("trails.graph")

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
end

function M.move_focus(dir)
    local focused_node_key = M.layer_to_node_keys[M.focused_node_key_index[1]][M.focused_node_key_index[2]]
    local focused_node = M.key_to_node[focused_node_key]
    if dir == 'l' then
        if focused_node then
            if focused_node.expanded then
                if focused_node.children then
                    M.focused_node_key_index[1] = M.focused_node_key_index[1] + 1
                end
            else
                M.expand_node(focused_node)
            end
        end
    elseif dir == 'h' then
        M.focused_node_key_index[1] = M.focused_node_key_index[1] - 1
    elseif dir == 'j' then
        M.focused_node_key_index[2] = M.focused_node_key_index[2] + 1
    elseif dir == 'k' then
        M.focused_node_key_index[2] = M.focused_node_key_index[2] - 1
    end

    -- Ensure we don't go outside the layouted graph
    if M.focused_node_key_index[1] < 1 then
        M.focused_node_key_index[1] = 1
    end
    if M.focused_node_key_index[2] < 1 then
        M.focused_node_key_index[2] = 1
    end
    local layer_count = #M.layer_to_node_keys
    if M.focused_node_key_index[1] > layer_count then
        M.focused_node_key_index[1] = layer_count
    end
    local count_in_layer = #M.layer_to_node_keys[M.focused_node_key_index[1]]
    if M.focused_node_key_index[2] > count_in_layer then
        M.focused_node_key_index[2] = count_in_layer
    end

    focused_node_key = M.layer_to_node_keys[M.focused_node_key_index[1]][M.focused_node_key_index[2]]
    M.print_lines_to_buffer(M.buf, g.draw_graph(M.key_to_node_with_fake, focused_node_key, M.layer_to_node_keys, M.layer_widht))
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
        M.focused_node_key_index = {1, 1}
        for _, c_full in ipairs(result) do
            local c = c_full["from"]
            local node = g.create_node(c.name, c.kind, c.uri, c.detail, false,
                                       c.range, c_full["fromRange"],
                                       c.selectionRange, g.make_key(c.name, c.uri), {})
            M.key_to_node[node.key] = node
            table.insert(root.children, node)
        end
        root.expanded = true
        M.root = root
    end
    M.open_split()
    M.layer_to_node_keys, M.layer_widht, M.key_to_node_with_fake = g.layout_graph(M.root, M.key_to_node)
    local focused_node_key = M.layer_to_node_keys[M.focused_node_key_index[1]][M.focused_node_key_index[2]]
    M.print_lines_to_buffer(M.buf, g.draw_graph(M.key_to_node_with_fake, focused_node_key, M.layer_to_node_keys, M.layer_widht))
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
            M.key_to_node[node_key] = node
        end
        table.insert(parent.children, node)
    end
    parent.expanded = true
    M.layer_to_node_keys, M.layer_widht, M.key_to_node_with_fake = g.layout_graph(M.root, M.key_to_node)
    local focused_node_key = M.layer_to_node_keys[M.focused_node_key_index[1]][M.focused_node_key_index[2]]
    M.print_lines_to_buffer(M.buf, g.draw_graph(M.key_to_node_with_fake, focused_node_key, M.layer_to_node_keys, M.layer_widht))
end

M.setup = function(opts)
    vim.lsp.handlers['callHierarchy/incomingCalls'] = vim.lsp.with(incomingCallsRoothandler, {})
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

local function rtrim(s)
  return s:match'^(.*%S)%s*$'
end

M.print_tree = function()
    --g.print_tree(M.root)
    g.print_tree(M.key_to_node_with_fake[M.layer_to_node_keys[1][1]])
end

M.print_lines_to_buffer = function(buf, lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, {})
    for i = 1, #lines do
        lines[i] = rtrim(lines[i])
    end

    --local info = vim.inspect(vim.api.nvim_get_all_options_info())
    --lines = {}
    --for line in info:gmatch("([^\n]*)\n?") do
    --    table.insert(lines, line)
    --end
    vim.api.nvim_buf_set_lines(buf, 0, #lines, false, lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
end


return M
