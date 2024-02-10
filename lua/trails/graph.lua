local G = {}

function G.make_key(name, uri)
    return name.."-"..uri
end

function G.print_tree(root, indent)
    indent = indent or ""
    print(indent .. root.key)

    indent = indent .. "  "
    for _, child in pairs(root.children) do
        G.print_tree(child, indent)
    end

end

function G.create_node(name, kind, uri, detail, expanded, range, from_ranges, selectionRange, key, children)
    return {
            name = name,
            kind = kind,
            uri = uri,
            key = key,
            detail = detail,
            expanded = expanded,
            range = range,
            from_ranges = from_ranges,
            selectionRange = selectionRange,
            children = children
    }
end

function G.clone_node(node)
    local children = {}
    -- TODO(amatej): There still are the original children objects!! I really have to use just keys..
    for _, child in pairs(node.children) do
        table.insert(children, child)
    end

    return G.create_node (
            node.name,
            node.kind,
            node.uri,
            node.detail,
            node.expanded,
            node.range,
            node.from_ranges,
            node.selectionRange,
            node.key,
            children
    )
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
    --pos = vim.str_utfindex(str, pos)
    return vim.fn.strcharpart(str, 0, pos) .. r .. vim.fn.strcharpart(str, pos+1)
end

local function add_edge(pos, str, edge)
    --print(vim.inspect("called: " .. pos .. " str: " .. str .. " with trad len: " .. #str))

    --print(("add edge with str \"" .. str .. "\" with len: " .. vim.str_byteindex(str, vim.str_utfindex(str, #str)) .. " edge: " .. edge))
    local current_edge = vim.fn.strgetchar(str, pos)
    --print(("current edge: " .. vim.fn.nr2char(current_edge) .. " from pos: " .. pos))
    if edge == '┐' then
        if current_edge == vim.fn.char2nr(' ') then
            str = replace_char(pos, str, edge)
        elseif current_edge == vim.fn.char2nr('─') then
            str = replace_char(pos, str, '┬')
        end
    elseif edge == '│' then
        if current_edge == vim.fn.char2nr(' ') then
            str = replace_char(pos, str, edge)
        elseif current_edge == vim.fn.char2nr('└') then
            str = replace_char(pos, str, '├')
        elseif current_edge == vim.fn.char2nr('┘') then
            str = replace_char(pos, str, '┤')
        end
    elseif edge == '└' then
        if current_edge == vim.fn.char2nr(' ') then
            str = replace_char(pos, str, edge)
        end
    elseif edge == '►' then
        str = replace_char(pos, str, edge)
    elseif edge == '─' then
        if current_edge == vim.fn.char2nr(' ') then
            str = replace_char(pos, str, edge)
        end
    elseif edge == '┘' then
        if current_edge == vim.fn.char2nr(' ') then
            str = replace_char(pos, str, edge)
        end
    elseif edge == '┌' then
        if current_edge == vim.fn.char2nr(' ') then
            str = replace_char(pos, str, edge)
        elseif current_edge == vim.fn.char2nr('─') then
            str = replace_char(pos, str, '┬')
        elseif current_edge == vim.fn.char2nr('┤') then
            str = replace_char(pos, str, '┼')
        end
    end

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

local remove_node_by_key = function(list, item)
    local new_list = {}
    for _, i in ipairs(list) do
        if i.key ~= item then
            table.insert(new_list, i)
        end
    end

    return new_list
end

G.layout_graph = function(root, key_to_node)
    local column = {root}
    local node_to_layer = {}
    local layer_count = 0
    while not vim.tbl_isempty(column) do
        layer_count = layer_count + 1
        local next_column = {}
        for node_index = 1, #column do
            local mynode = column[node_index]
            if node_to_layer[mynode.key] then
                if node_to_layer[mynode.key] < layer_count then
                    node_to_layer[mynode.key] = layer_count
                end
            else
                node_to_layer[mynode.key] = layer_count
            end

            if mynode.expanded or mynode == root then
                for j = 1, #mynode.children do
                    table.insert(next_column, mynode.children[j])
                end
            end
        end

        column = next_column
    end

    local layer_width = {}
    local layer_to_node_keys_with_fake = {}
    for node_key, layer_index in pairs(node_to_layer) do
        local node = key_to_node[node_key]
        if (node == nil) then
            P(node_key .. " is nil node")
        end

        if not layer_to_node_keys_with_fake[layer_index] then
            layer_to_node_keys_with_fake[layer_index] = {}
        end
        table.insert(layer_to_node_keys_with_fake[layer_index], node_key)

        if not layer_width[layer_index] then
            layer_width[layer_index] = string.len(node.name)
        else
            if layer_width[layer_index] < string.len(node.name) then
                layer_width[layer_index] = string.len(node.name)
            end
        end
    end

    -- Clone all nodes so we can insert fakes
    local key_to_node_with_fake = {}
    for _,v in pairs(key_to_node) do
        local source_clone = G.clone_node(v)
        key_to_node_with_fake[source_clone.key] = source_clone
    end

    -- Insert fake nodes
    for layer_index = 1, layer_count do
        -- Consider only from the second layer, there are no connections to the first layer.
        if layer_index ~= 1 then
            local sources = layer_to_node_keys_with_fake[layer_index-1]
            local targets = layer_to_node_keys_with_fake[layer_index]
            for _, source_key in pairs(sources) do
                local source = key_to_node_with_fake[source_key]
                for _, child in pairs(source.children) do
                    if not vim.tbl_contains(targets, child.key) then
                        local fake_node_key = source.key .. ".fake-child"
                        if not key_to_node_with_fake[fake_node_key] then
                            local fake_node = G.create_node("───", 0, "", "", true, {}, nil, nil, fake_node_key, {child})
                            key_to_node_with_fake[fake_node_key] = fake_node
                            table.insert(source.children, fake_node)
                            source.children = remove_node_by_key(source.children, child.key)
                            table.insert(layer_to_node_keys_with_fake[layer_index], fake_node_key)
                        end
                    end
                end
                key_to_node_with_fake[source_key] = source
            end
        end
    end

    -- Wrap all of these into a graph table
    return layer_to_node_keys_with_fake, layer_width, key_to_node_with_fake
end

G.draw_graph = function(key_to_node, active_node_key, layer_to_node_keys, layer_width)
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
                    lines[current_line] = lines[current_line] .. "──" ..  mynode.name .. "─" .. "─"
            end
            if #mynode.name < layer_width[layer_index] then
                local current_name_len = #mynode.name
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


return G
