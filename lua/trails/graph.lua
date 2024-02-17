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

return G
