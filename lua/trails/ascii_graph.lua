local A = {}
local u = require("trails.utils")
local g = require("trails.graph")

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

-- start is a char cound from the begining of the line (not byte count)
-- len is byte len (not char len)
local function add_active_segment(highlight_positions, line, start, len)
    local active_segment = {}
    active_segment.line = line
    active_segment.start = start
    active_segment.len = len
    if highlight_positions ~= nil then
        table.insert(highlight_positions, active_segment)
    end
end

-- By default all edges go just straight we have to figure out what to do here
local function add_connection(lines, starting_index, source_i, child_i, connection_layer_widht, highlight_positions)
    local walked = 0
    if source_i == child_i then
        lines[source_i] = add_edge(starting_index + walked, lines[source_i], '─')
        walked = walked + 1
        lines[source_i] = add_edge(starting_index + walked, lines[source_i], '─')
        walked = walked + 1
        add_active_segment(highlight_positions, source_i, starting_index + walked - 2, #'─'*2)
    elseif source_i < child_i then
        while source_i < child_i do
            lines[source_i] = add_edge(starting_index + walked, lines[source_i], '┐')
            add_active_segment(highlight_positions, source_i, starting_index + walked, #'┐')
            source_i = source_i + 1
            lines[source_i] = add_edge(starting_index + walked, lines[source_i], '└')
            add_active_segment(highlight_positions, source_i, starting_index + walked, #'└')
            walked = walked + 1
        end
        lines[source_i] = add_edge(starting_index + walked, lines[source_i], '─')
        add_active_segment(highlight_positions, source_i, starting_index + walked, #'─')
        walked = walked + 1
    elseif source_i > child_i then
        while source_i > child_i do
            lines[source_i] = add_edge(starting_index + walked, lines[source_i], '┘')
            add_active_segment(highlight_positions, source_i, starting_index + walked, #'┘')
            source_i = source_i - 1
            lines[source_i] = add_edge(starting_index + walked, lines[source_i], '┌')
            add_active_segment(highlight_positions, source_i, starting_index + walked, #'┌')
            walked = walked + 1
        end
        lines[source_i] = add_edge(starting_index + walked, lines[source_i], '─')
        add_active_segment(highlight_positions, source_i, starting_index + walked, #'─')
        walked = walked + 1
    end


    local hi_start = starting_index + walked
    while (walked <= connection_layer_widht) do
        lines[source_i] = add_edge(starting_index + walked, lines[source_i], '─')
        walked = walked + 1
    end
    add_active_segment(highlight_positions, source_i, hi_start, #'─'*(starting_index + walked - hi_start))
    return walked
end

A.draw_graph = function(key_to_node, active_key_start, active_key_end, layer_to_node_keys)
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

    local highlight_positions = {}
    local expanded_positions = {}
    local active_node_pos = {1, 1}

    for layer_index = 1, layer_count do
        local layer_nodes = padded_layer_to_node_keys[layer_index]

        -- We have written at least one full layer -> we can create connections to the next
        local connection_layer_widht = 0
        if layer_index ~= 1 then
            local targets = padded_layer_to_node_keys[layer_index]
            local sources = padded_layer_to_node_keys[layer_index-1]
            -- All lines should have the same starting width
            local starting_index = vim.fn.strcharlen(lines[1])

            -- Compute connection layer width
            for source_i, source_key in pairs(sources) do
                local source = key_to_node[source_key]
                for _, child in pairs(source.children) do
                    local child_i = u.get_value_index(targets, child.key)
                    if child_i ~= -1 then
                        if connection_layer_widht < math.abs(source_i - child_i) then
                            connection_layer_widht = math.abs(source_i - child_i)
                        end
                    end
                end
            end

            for source_i, source_key in pairs(sources) do
                local source = key_to_node[source_key]
                --P("source: " .. source.name .. " with " .. #source.children)
                if source.expanded then
                    for _, child in pairs(source.children) do
                        local child_i = u.get_value_index(targets, child.key)
                        if child_i ~= -1 then
                            if ((source.connecting_from == active_key_start or source.key == active_key_start) and child.key == active_key_end) or
                               ((source.connecting_from == active_key_start or source.key == active_key_start) and child.connecting_to == active_key_end) then
                                add_connection(lines, starting_index, source_i, child_i, connection_layer_widht, highlight_positions)
                            else
                                add_connection(lines, starting_index, source_i, child_i, connection_layer_widht, nil)
                            end
                        end
                    end
                end
            end

            -- Make sure all lines have the same len
            for i = 1, #lines do
                local target_key = targets[i]
                if target_key ~= nil then
                    local filler = " "
                    if target_key ~= "empty" then
                        filler = "─"
                    end

                    while (vim.fn.strcharlen(lines[i]) <= connection_layer_widht + starting_index) do
                        lines[i] = lines[i] .. filler
                    end

                end
            end
        end

        local current_line = 1
        for _, node_key in pairs(layer_nodes) do
            local mynode = key_to_node[node_key]

            -- Highligh name
            if mynode.key == active_key_start and mynode.key == active_key_end then
                add_active_segment(highlight_positions, current_line, vim.fn.strcharlen(lines[current_line]), #mynode.name + 2) -- +2 for brackets
            end

            if (mynode.type == g.NodeType.Empty) then
                lines[current_line] = lines[current_line] .. " " ..  mynode.name .. " "
            elseif (mynode.type == g.NodeType.Regular) then
                if mynode.expanded then
                    add_active_segment(expanded_positions, current_line, vim.fn.strcharlen(lines[current_line]), #mynode.name + 2) -- +2 for brackets
                end
                lines[current_line] = lines[current_line] .. "[" ..  mynode.name .. "]"
            elseif (mynode.type == g.NodeType.Connection) then
                local before_name_start = vim.fn.strcharlen(lines[current_line])
                lines[current_line] = lines[current_line] .. "─" ..  mynode.name .. "─"
                if (mynode.connecting_from == active_key_start and mynode.connecting_to == active_key_end) then
                    add_active_segment(highlight_positions, current_line, before_name_start, 2*#"─" + #mynode.name)
                end
            else
                error("Invalid NodeType for node: " .. vim.inspect(mynode))
            end

            if mynode.key == active_key_end then
                active_node_pos[1] = current_line
                if active_key_end == active_key_start then
                    active_node_pos[2] = #lines[current_line] - 1
                else
                    active_node_pos[2] = #lines[current_line] - 2 - #mynode.name -- -2 for brackets
                end
            end


            local after_name_start_byte = #lines[current_line]
            local after_name_start = vim.fn.strcharlen(lines[current_line])

            if mynode.expanded and #mynode.children > 0 then
                if mynode.type == g.NodeType.Regular then
                    lines[current_line] = lines[current_line] .. '◄'
                elseif mynode.type == g.NodeType.Connection then
                    lines[current_line] = lines[current_line] .. '─'
                end
            else
                lines[current_line] = lines[current_line] .. ' '
            end

            local current_name_len = vim.fn.strcharlen(mynode.name)
            while current_name_len < layer_width[layer_index] do
                if mynode.expanded and #mynode.children > 0 then
                    lines[current_line] = lines[current_line] .. '─'
                else
                    lines[current_line] = lines[current_line] .. ' '
                end
                current_name_len = current_name_len + 1
            end

            if (mynode.key == active_key_start and mynode.key ~= active_key_end) or
               (mynode.connecting_from == active_key_start and mynode.connecting_to == active_key_end) then
                add_active_segment(highlight_positions, current_line, after_name_start, #lines[current_line] - after_name_start_byte)
            end

            current_line = current_line + 1
        end
    end

    for i = 1, #lines do
        lines[i] = rtrim(lines[i])
    end

    return lines, highlight_positions, active_node_pos, expanded_positions
end

return A
