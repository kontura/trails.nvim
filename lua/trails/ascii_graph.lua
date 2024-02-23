local A = {}
local u = require("trails.utils")

-- UP=first bit, RIGHT=second bit, DOWN=third bit, LEFT=fourth bit
A.path_lookup = {
    [0b0000] = ' ',
    [0b1010] = '│',
    [0b0101] = '─',

    [0b1100] = '└',
    [0b1001] = '┘',
    [0b0110] = '┌',
    [0b0011] = '┐',

    [0b0111] = '┬',
    [0b1101] = '┴',
    [0b1110] = '├',
    [0b1011] = '┤',

    [0b1111] = '┼',
}
A.path_reverse_lookup = {
    [' '] =  0b0000,
    ['│'] =  0b1010,
    ['─'] =  0b0101,

    ['└'] =  0b1100,
    ['┘'] =  0b1001,
    ['┌'] =  0b0110,
    ['┐'] =  0b0011,

    ['┬'] =  0b0111,
    ['┴'] =  0b1101,
    ['├'] =  0b1110,
    ['┤'] =  0b1011,

    ['┼'] =  0b1111,
}

local function rtrim(s)
  return s:match'^(.*%S)%s*$'
end

local function add_binary_edges(one, two)
    return bit.bor(one, two)
end

local function replace_char(pos, str, r)
    return vim.fn.strcharpart(str, 0, pos) .. r .. vim.fn.strcharpart(str, pos+1)
end

local function add_edge(pos, str, edge)
    while (vim.fn.strcharlen(str) <= pos) do
        str = str .. " "
    end
    local current_edge = vim.fn.strgetchar(str, pos)
    local current_edge_bin = A.path_reverse_lookup[vim.fn.nr2char(current_edge)]
    -- In case we encounter unknown current edge/some other symbol that is not in the table
    -- just overwrite it.
    if current_edge_bin == nil then
        current_edge_bin = A.path_reverse_lookup[" "]
    end
    local edge_bin = A.path_reverse_lookup[edge]
    str = replace_char(pos, str, A.path_lookup[add_binary_edges(current_edge_bin, edge_bin)])

    return str
end

-- By default all edges go just straight we have to figure out what to do here
local function _add_connection(lines, starting_index, source_i, child_i)
    local walked = 0
    if source_i == child_i then
        lines[source_i] = add_edge(starting_index + walked, lines[source_i], '─')
        walked = walked + 1
        lines[source_i] = add_edge(starting_index + walked, lines[source_i], '─')
        walked = walked + 1
    elseif source_i < child_i then
        while source_i < child_i do
            lines[source_i] = add_edge(starting_index + walked, lines[source_i], '┐')
            source_i = source_i + 1
            lines[source_i] = add_edge(starting_index + walked, lines[source_i], '└')
            walked = walked + 1
        end
        lines[source_i] = add_edge(starting_index + walked, lines[source_i], '─')
        walked = walked + 1
    elseif source_i > child_i then
        while source_i > child_i do
            lines[source_i] = add_edge(starting_index + walked, lines[source_i], '┘')
            source_i = source_i - 1
            lines[source_i] = add_edge(starting_index + walked, lines[source_i], '┌')
            walked = walked + 1
        end
        lines[source_i] = add_edge(starting_index + walked, lines[source_i], '─')
        walked = walked + 1
    end
    return walked
end

local draw_node = function(node, layer_width, active_node_key)
    local line = ""
    local expanded = 'C'
    if node.expanded then
        expanded = 'E'
    end
    if (node.key == "empty") then
        line = line .. " " ..  node.name .. " " .. " "
    elseif node.name ~= "───" then
        if node.key == active_node_key then
            line = line .. "<" ..  node.name .. expanded .. ">"
        else
            line = line .. "[" ..  node.name .. expanded .. "]"
        end
    else
        --P(vim.fn.strcharlen(node.name) .. " is len of " .. node.name)
        --P(#node.name)
        line = line .. "─" ..  node.name .. "─" .. "─"
    end
    if vim.fn.strcharlen(node.name) < layer_width then
        local current_name_len = vim.fn.strcharlen(node.name)
        while current_name_len < layer_width do
            if node.expanded and #node.children > 0 then
                line = line .. '─'
            else
                line = line .. ' '
            end
            current_name_len = current_name_len + 1
        end
    end

    if node.expanded and #node.children > 0 then
        -- if is not fake, TODO(amatej): maybe create a better condition if node.is_fake then
        if node.name ~= "───" then
            line = line .. '◄'
        else
            line = line .. '─'
        end
    else
        line = line .. ' '
    end

    return line
end

A.draw_graph = function(key_to_node, active_node_key, layer_to_node_keys)
    local layer_width = {}
    local max_lines = 1
    local layer_count = #layer_to_node_keys
    local padded_layer_to_node_keys = {}
    for layer_index = 1, layer_count do
        if layer_to_node_keys[layer_index] then
            layer_width[layer_index] = 0
            local layer_nodes = layer_to_node_keys[layer_index]
            local padded_layer_node_keys = {}
            for _, node_key in pairs(layer_nodes) do
                local mynode = key_to_node[node_key]
                if vim.fn.strcharlen(mynode.name) > layer_width[layer_index] then
                    layer_width[layer_index] = vim.fn.strcharlen(mynode.name)
                end
                table.insert(padded_layer_node_keys, node_key)
                table.insert(padded_layer_node_keys, "empty")
            end
            padded_layer_to_node_keys[layer_index] = padded_layer_node_keys
            if max_lines < #padded_layer_node_keys then
                max_lines = #padded_layer_node_keys
            end
        else
            padded_layer_to_node_keys[layer_index] = {}
        end
    end


    local lines = {}
    for _ = 1, max_lines do
        table.insert(lines, "")
    end

    --P("Printing: " .. layer_to_node_keys[1][1])
    --G.print_tree(key_to_node[layer_to_node_keys[1][1]])

    for layer_index = 1, layer_count do
        local layer_nodes = padded_layer_to_node_keys[layer_index]

        -- We have written at least one full layer -> we can create connections to the next
        local max_connection_width = 0 -- minimum width is 3
        if layer_index ~= 1 then
            local targets = padded_layer_to_node_keys[layer_index]
            local sources = padded_layer_to_node_keys[layer_index-1]
            -- All lines should have the same starting width
            local starting_index = vim.fn.strcharlen(lines[1])
            for source_i, source_key in pairs(sources) do
                local source = key_to_node[source_key]
                --P("source: " .. source.name .. " with " .. #source.children)
                for _, child in pairs(source.children) do
                    --P("  " .. child.name)
                    if vim.tbl_contains(targets, child.key) then
                        -- At the end I will have to extend all lenghts
                        local con_width = _add_connection(lines, starting_index, source_i, u.get_value_index(targets, child.key))
                        if max_connection_width < con_width then
                            max_connection_width = con_width
                        end
                    end
                end
            end

            -- Make sure all lines have the same len
            for i = 1, #lines do
                local mynode_key = targets[i]
                if mynode_key ~= nil then
                    local filler = " "
                    if mynode_key ~= "empty" then
                        filler = "─"
                    end

                    while (vim.fn.strcharlen(lines[i]) < max_connection_width + starting_index) do
                        lines[i] = lines[i] .. filler
                    end

                end
            end
        end

        local current_line = 1
        for _, node_key in pairs(layer_nodes) do
            local mynode = key_to_node[node_key]

            lines[current_line] = lines[current_line] .. draw_node(mynode, layer_width[layer_index], active_node_key)
            current_line = current_line + 1
        end

        for line_index = current_line, max_lines do
            -- 2 square brackets + 1 for exanded
            if layer_width[layer_index] then
                for _ = 1, layer_width[layer_index]+ max_connection_width + 2 + 1 do
                  lines[line_index] = lines[line_index] .. " "
                end
            end
        end
    end

    for i = 1, #lines do
        lines[i] = rtrim(lines[i])
    end

    return lines
end

return A
