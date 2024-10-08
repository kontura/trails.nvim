local G = {}
local u = require("trails.utils")

G.get_key_index = function(layer_to_node_keys, key)
    for layer_i, layer in ipairs(layer_to_node_keys) do
        for node_key_i, node_key in ipairs(layer) do
            if node_key == key then
                return {layer_i, node_key_i}
            end
        end
    end
end

function G.make_key(name, uri)
    return name.."-"..uri
end

G.is_crossing = function(a_start, a_end, b_start, b_end)
    if (a_start == b_start) then
        return 0
    end
    if (a_end == b_end) then
        return 0
    end

    if ((a_start < b_start and a_end > b_end) or (a_start > b_start and a_end < b_end)) then
        return 1
    end
    return 0
end

G.count_crossings = function(key_to_node, layer_to_node_keys)
    local layer_count = #layer_to_node_keys
    local crossings = 0

            --crossings = vim.inspect(layer_to_node_keys)
    for layer_index = 2, layer_count do
        local targets = layer_to_node_keys[layer_index]
        local sources = layer_to_node_keys[layer_index-1]
        for sourceA_i, source_key in pairs(sources) do
            local sourceA = key_to_node[source_key]
            for _, childA in pairs(sourceA.children) do
                local tartgetA = u.get_value_index(targets, childA.key)
                for sourceB_i = sourceA_i, #sources do
                    local sourceB = key_to_node[sources[sourceB_i]]
                    for _, childB in pairs(sourceB.children) do
                        local tartgetB = u.get_value_index(targets, childB.key)
                        crossings = crossings + G.is_crossing(sourceA_i, tartgetA, sourceB_i, tartgetB)
                    end
                end
            end
        end
    end

    return crossings
end

G.count_len = function(key_to_node, layer_to_node_keys)
    local layer_count = #layer_to_node_keys
    local len = 0

    for layer_index = 2, layer_count do
        local targets = layer_to_node_keys[layer_index]
        local sources = layer_to_node_keys[layer_index-1]
        for sourceA_i, source_key in pairs(sources) do
            local sourceA = key_to_node[source_key]
            for _, childA in pairs(sourceA.children) do
                local tartgetA_i = u.get_value_index(targets, childA.key)
                len = len + math.abs(sourceA_i - tartgetA_i)
            end
        end
    end

    return len
end

local function shuffle(tbl)
  for i = #tbl, 2, -1 do
    local j = math.random(i)
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end
  return tbl
end

local function mutate_gene(layer)
    if (math.random(16) == 1) then
        local ii = math.random(#layer)
        table.insert(layer, ii, "empty")
    else
        local ii = math.random(#layer)
        local jj = math.random(#layer)
        layer[ii], layer[jj] = layer[jj], layer[ii]
    end
    return layer
end

local function mate(layer_to_node_keys1, layer_to_node_keys2)
    local child = {}
    for layer_index = 1, #layer_to_node_keys1 do
        local p = math.random(100)
        if (p < 30) then
            child[layer_index] = vim.deepcopy(layer_to_node_keys1[layer_index])
        end
        if (p < 60) then
            child[layer_index] = vim.deepcopy(layer_to_node_keys2[layer_index])
        end
        if (p <= 100) then
            child[layer_index] = mutate_gene(vim.deepcopy(layer_to_node_keys1[layer_index]))
        end
    end

    return child
end

function G.minimize_crossings_genetic(key_to_node, layer_to_node_keys)
    local POPULATION_SIZE = 30
    local population = {{gene = vim.deepcopy(layer_to_node_keys), fitness = 0}}
    for _ = 1, POPULATION_SIZE do
        local individual = {gene = vim.deepcopy(layer_to_node_keys), fitness = 0}
        for _, layer in pairs(individual.gene) do
            shuffle(layer)
        end

        table.insert(population, individual)
    end

    -- calculate fitness for all individuals
    for i = 1, #population do
        population[i].fitness = 5*G.count_crossings(key_to_node, population[i].gene) + G.count_len(key_to_node, population[i].gene)
        --P("Set fitness: " .. population[i].fitness)
        if population[i].fitness == 0 then
            --P("Returning genom 0")
            return population[i].gene
        end
    end

    -- EXAMPLE 40 iterations loop
    for _ = 1, 140 do
        table.sort(population, function(left, right)
            return left.fitness < right.fitness
        end)

        local new_generation = {}
        local s = (10*POPULATION_SIZE)/100;
        for i = 1, s do
            table.insert(new_generation, vim.deepcopy(population[i]))
        end

        -- From 50% of fittest population, Individuals will mate to produce offspring
        s = (90*POPULATION_SIZE)/100;
        local half = POPULATION_SIZE/2
        for _ = 1, s do
            local j = math.random(half)
            local i = math.random(half)
            local child = mate(population[j].gene, population[i].gene)
            local individual = {gene = child, fitness = 0}
            table.insert(new_generation, individual)
        end

        population = new_generation

        for i = 1, #population do
            population[i].fitness = 10*G.count_crossings(key_to_node, population[i].gene) + G.count_len(key_to_node, population[i].gene)
            --P("Set fitness: " .. population[i].fitness)
            if population[i].fitness == 0 then
                return population[i].gene
            end
        end
    end

    --P("Best fitness: " .. population[1].fitness)
    --P(population[1].gene)
    return population[1].gene
end

function G.print_tree(root, indent, printed)
    if printed[root.key] then
        return
    end
    indent = indent or ""
    print(indent .. root.key)
    printed[root.key] = true

    indent = indent .. "  "
    for _, child in pairs(root.children) do
        G.print_tree(child, indent, printed)
    end

end

G.NodeType = {
   Empty = {},
   Connection = {},
   Regular = {},
}

function G.create_node(name, kind, uri, detail, expanded, range, from_ranges, selectionRange, key, children, type)
    type = type or G.NodeType.Regular
    return {
            name = name,
            calls = {},
            kind = kind,
            uri = uri,
            key = key,
            detail = detail,
            expanded = expanded,
            range = range,
            from_ranges = from_ranges,
            selectionRange = selectionRange,
            children = children,
            type = type
    }
end

function G.create_connection_node(key, child, source)
    local node = G.create_node("───", 0, "", "", true, {}, nil, nil, key, {child}, G.NodeType.Connection)
    -- node.children can get changed if we connect to another connection node but we want
    -- to keep key of the real target node (for highlighting).
    node.connecting_to = child.connecting_to or child.key
    node.connecting_from = source.connecting_from or source.key
    return node
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

G.has_child_with_key = function(parent, candidate_child_key)
    for _, child in ipairs(parent.children) do
        if child.key == candidate_child_key then
            return true
        end
    end

    return false
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

G._add_connection_nodes = function(key_to_node_with_fake, layer_to_node_keys)
    -- Consider only from the second layer, there are no connections to the first layer.
    for layer_index = 2, #layer_to_node_keys do
        local sources = layer_to_node_keys[layer_index-1]
        local targets = layer_to_node_keys[layer_index]
        for _, source_key in pairs(sources) do
            local source = key_to_node_with_fake[source_key]
            if source.expanded then
                for _, child in pairs(source.children) do
                    if not vim.tbl_contains(targets, child.key) then
                        -- This is not the most elegant, but I need both source and child keys in the
                        -- connection node key to make sure its unique. For connection nodes through
                        -- multiple layers it will look like: source_key->child_key->child_key->child_key
                        local fake_node_key = source.key.."->"..child.key
                        if not key_to_node_with_fake[fake_node_key] then
                            local connection_node = G.create_connection_node(fake_node_key, child, source)
                            key_to_node_with_fake[fake_node_key] = connection_node
                            table.insert(source.children, connection_node)
                            source.children = remove_node_by_key(source.children, child.key)
                            table.insert(layer_to_node_keys[layer_index], fake_node_key)
                        end
                    end
                end
            end
            key_to_node_with_fake[source_key] = source
        end
    end
end

G._assign_nodes_to_layers = function(root, key_to_node)
    local column = {root}
    local node_to_layer = {}
    local layer_count = 0
    while not vim.tbl_isempty(column) do
        layer_count = layer_count + 1
        local next_column = {}
        for node_index = 1, #column do
            local mynode = column[node_index]
            if node_to_layer[mynode.key] then
                if node_to_layer[mynode.key] < layer_count and mynode ~= root then
                    node_to_layer[mynode.key] = layer_count
                end
            else
                node_to_layer[mynode.key] = layer_count
                if mynode.expanded or mynode == root then
                    for j = 1, #mynode.children do
                        table.insert(next_column, mynode.children[j])
                    end
                end
            end
        end

        column = next_column
    end

    return node_to_layer
end

G._transform_to_layers = function(key_to_node, node_to_layer)
    local layer_to_node_keys = {}
    for node_key, layer_index in pairs(node_to_layer) do
        local node = key_to_node[node_key]
        if (node == nil) then
            P(node_key .. " is nil node")
        end

        if not layer_to_node_keys[layer_index] then
            layer_to_node_keys[layer_index] = {}
        end
        table.insert(layer_to_node_keys[layer_index], node_key)
    end

    -- Prune empty layers
    local pruned_layer_to_node_keys = {}
    local new_index = 1
    for j = 1, #layer_to_node_keys do
        if layer_to_node_keys[j] and not vim.tbl_isempty(layer_to_node_keys[j]) then
            pruned_layer_to_node_keys[new_index] = layer_to_node_keys[j]
            layer_to_node_keys[j] = nil
            new_index = new_index + 1
        end
    end

    return pruned_layer_to_node_keys
end

G.layout_graph = function(root, key_to_node)
    local node_to_layer = G._assign_nodes_to_layers(root, key_to_node)

    local layer_to_node_keys = G._transform_to_layers(key_to_node, node_to_layer)

    -- Clone all nodes so we can insert fakes
    local key_to_node_with_fake = {}
    for _,v in pairs(key_to_node) do
        local source_clone = G.clone_node(v)
        key_to_node_with_fake[source_clone.key] = source_clone
    end
    -- Insert just once empty node that can be used throughout the graph
    key_to_node_with_fake.empty = {name="", children={}, key="empty", expanded = true, type = G.NodeType.Empty}

    G._add_connection_nodes(key_to_node_with_fake, layer_to_node_keys)

    layer_to_node_keys = G.minimize_crossings_genetic(key_to_node_with_fake, layer_to_node_keys)

    -- Wrap all of these into a graph table
    return layer_to_node_keys, key_to_node_with_fake
end

return G
