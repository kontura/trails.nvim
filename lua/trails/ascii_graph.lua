local A = {}

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

local function add_binary_edges(one, two)
    return bit.bor(one, two)
end


local function get_value_index(list, value)
    for i,v in pairs(list) do
        if v == value then
            return i
        end
    end
    return -1
end

local function replace_char(pos, str, r)
    return vim.fn.strcharpart(str, 0, pos) .. r .. vim.fn.strcharpart(str, pos+1)
end

local function add_edge(pos, str, edge)
    local current_edge = vim.fn.strgetchar(str, pos)
    local current_edge_bin = A.path_reverse_lookup[vim.fn.nr2char(current_edge)]
    local edge_bin = A.path_reverse_lookup[edge]
    str = replace_char(pos, str, A.path_lookup[add_binary_edges(current_edge_bin, edge_bin)])

    return str
end

-- By default all edges go just straight we have to figure out what to do here
local function _add_connection(lines, source_i, child_i)
    if source_i == child_i then
        lines[source_i] = add_edge(vim.fn.strcharlen(lines[source_i]) - 2, lines[source_i], '─')
        lines[source_i] = add_edge(vim.fn.strcharlen(lines[source_i]) - 1, lines[source_i], '─')
    elseif source_i < child_i then
        lines[source_i] = add_edge(vim.fn.strcharlen(lines[source_i]) - 2, lines[source_i], '┐')
        source_i = source_i + 1
        while source_i < child_i do
            lines[source_i] = add_edge(vim.fn.strcharlen(lines[source_i]) - 2, lines[source_i], '│')
            source_i = source_i + 1
        end
        lines[source_i] = add_edge(vim.fn.strcharlen(lines[source_i]) - 2, lines[source_i], '└')
        lines[source_i] = add_edge(vim.fn.strcharlen(lines[source_i]) - 1, lines[source_i], '─')
    elseif source_i > child_i then
        lines[source_i] = add_edge(vim.fn.strcharlen(lines[source_i]) - 2, lines[source_i], '┘')
        source_i = source_i - 1
        while source_i > child_i do
            lines[source_i] = add_edge(vim.fn.strcharlen(lines[source_i]) - 2, lines[source_i], '│')
            source_i = source_i - 1
        end
        lines[source_i] = add_edge(vim.fn.strcharlen(lines[source_i]) - 2, lines[source_i], '┌')
        lines[source_i] = add_edge(vim.fn.strcharlen(lines[source_i]) - 1, lines[source_i], '─')
    end
end

A.draw_graph = function(key_to_node, active_node_key, layer_to_node_keys, layer_width)
    local max_lines = 1
    local layer_count = #layer_to_node_keys
    for layer_index = 1, layer_count do
        if layer_to_node_keys[layer_index] then
            local layer_nodes = layer_to_node_keys[layer_index]
            if max_lines < #layer_nodes then
                max_lines = #layer_nodes
            end
        else
            layer_to_node_keys[layer_index] = {}
        end
    end


    local lines = {}
    for _ = 1, max_lines do
        table.insert(lines, "")
    end

    --P("Printing: " .. layer_to_node_keys[1][1])
    --G.print_tree(key_to_node[layer_to_node_keys[1][1]])

    for layer_index = 1, layer_count do
        local current_line = 1
        local layer_nodes = layer_to_node_keys[layer_index]

        -- We have written at least one full layer -> we can create connections to the next
        if layer_index ~= 1 then
            local targets = layer_to_node_keys[layer_index]
            local sources = layer_to_node_keys[layer_index-1]
            for source_i, source_key in pairs(sources) do
                local source = key_to_node[source_key]
                --P("source: " .. source.name .. " with " .. #source.children)
                for _, child in pairs(source.children) do
                    --P("  " .. child.name)
                    if vim.tbl_contains(targets, child.key) then
                        _add_connection(lines, source_i, get_value_index(targets, child.key))
                    end
                end
            end
        end

        for _, node_key in pairs(layer_nodes) do
            local mynode = key_to_node[node_key]

            local expanded = 'C'
            if mynode.expanded then
                expanded = 'E'
            end
            if mynode.name ~= "───" then
                    if mynode.key == active_node_key then
                        lines[current_line] = lines[current_line] .. "<" ..  mynode.name .. expanded .. ">"
                    else
                        lines[current_line] = lines[current_line] .. "[" ..  mynode.name .. expanded .. "]"
                    end
                else
                    lines[current_line] = lines[current_line] .. "─" ..  mynode.name .. "─" .. "─"
            end
            if vim.fn.strcharlen(mynode.name) < layer_width[layer_index] then
                local current_name_len = vim.fn.strcharlen(mynode.name)
                while current_name_len < layer_width[layer_index] do
                    if mynode.expanded and #mynode.children > 0 then
                        lines[current_line] = lines[current_line] .. '─'
                    else
                        lines[current_line] = lines[current_line] .. ' '
                    end
                    current_name_len = current_name_len + 1
                end
            end

            if mynode.expanded and #mynode.children > 0 then
                -- if is not fake, TODO(amatej): maybe create a better condition if mynode.is_fake then
                if mynode.name ~= "───" then
                    lines[current_line] = lines[current_line] .. '◄  '
                else
                    lines[current_line] = lines[current_line] .. '─  '
                end
            else
                lines[current_line] = lines[current_line] .. '   '
            end

            current_line = current_line + 1
        end

        for line_index = current_line, max_lines do
            -- 2 square brackets and 3 for graph lines + 1 for exanded
            if layer_width[layer_index] then
                for _ = 1, layer_width[layer_index]+6 do
                  lines[line_index] = lines[line_index] .. " "
                end
            end
        end
    end


    return lines
end

A.is_crossing = function(a_start, a_end, b_start, b_end)
    if (a_start == b_start) then
        return 0
    end
    if (a_end == b_end) then
        return 0
    end

    local x1, x2, y1, y2
    if (a_start < a_end) then
        x1 = a_start
        x2 = a_end
    else
        x1 = a_end
        x2 = a_start
    end
    if (b_start < b_end) then
        y1 = b_start
        y2 = b_end
    else
        y1 = b_end
        y2 = b_start
    end


    if (x1 <= y2 and y1 <= x2) then
        return 1
    end
    return 0
end

A.count_crossings = function(key_to_node, layer_to_node_keys)
    local layer_count = #layer_to_node_keys
    local crossings = 0

            --crossings = vim.inspect(layer_to_node_keys)
    for layer_index = 2, layer_count do
        local targets = layer_to_node_keys[layer_index]
        local sources = layer_to_node_keys[layer_index-1]
        for sourceA_i, source_key in pairs(sources) do
            local sourceA = key_to_node[source_key]
            for _, childA in pairs(sourceA.children) do
                local tartgetA = get_value_index(targets, childA.key)
                for sourceB_i = sourceA_i, #sources do
                    local sourceB = key_to_node[sources[sourceB_i]]
                    for _, childB in pairs(sourceB.children) do
                        local tartgetB = get_value_index(targets, childB.key)
                        crossings = crossings + A.is_crossing(sourceA_i, tartgetA, sourceB_i, tartgetB)
                    end
                end
            end
        end
    end

    return crossings
end

return A
