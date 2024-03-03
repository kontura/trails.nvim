local MV = {}

local g = require("trails.graph")
local u = require("trails.utils")

MV.graph_move = function(layer_to_node_keys, key_to_node, dir, index_start, index_end)
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
        local layer_count = #layer_to_node_keys
        if index[1] > layer_count then
            return true
        end
        local count_in_layer = #layer_to_node_keys[index[1]]
        if index[2] > count_in_layer then
            return true
        end

        return false
    end

    --TODO(amatej): maybe do the copy later
    local i_start = vim.deepcopy(index_start)
    local i_end = vim.deepcopy(index_end)

    if vim.deep_equal(index_start, index_end) then
        -- We have a node selected
        if dir == 'j' or dir == 'k' then
            -- We move up/down to a node
            get_next(dir, i_start)
            if is_out_of_bounds(i_start) then
                return {index_start, index_end}
            end
            local new_focused_node_key = layer_to_node_keys[i_start[1]][i_start[2]]
            local new_focused_node = key_to_node[new_focused_node_key]

            while new_focused_node.type ~= g.NodeType.Regular do
                get_next(dir, i_start)
                if is_out_of_bounds(i_start) then
                    return {index_start, index_end}
                end
                new_focused_node_key = layer_to_node_keys[i_start[1]][i_start[2]]
                new_focused_node = key_to_node[new_focused_node_key]
            end

            return {i_start, vim.deepcopy(i_start)}

        else
            -- We move to a connecting edge
            if dir == 'l' then
                local focused_node_key = layer_to_node_keys[i_start[1]][i_start[2]]
                local focused_node = key_to_node[focused_node_key]
                -- We assume its expanded
                if #focused_node.children > 0 then
                    local first_child_key = focused_node.children[1].key
                    local child_layer = layer_to_node_keys[i_start[1]+1]
                    local child_index = u.get_value_index(child_layer, first_child_key)
                    if child_index ~= -1 then
                        return {i_start, {i_start[1]+1, child_index}}
                    else
                        error("Child not found in next layer, INVALID GRAPH")
                    end
                else
                    return {index_start, index_end}
                end
            end
            if dir == 'h' then
                if i_start[1] - 1 > 0 then
                    local child_key = layer_to_node_keys[i_start[1]][i_start[2]]
                    local parent_layer = layer_to_node_keys[i_start[1]-1]
                    for parent_i, parent_key in ipairs(parent_layer) do
                        local parent = key_to_node[parent_key]
                        for _, ch in ipairs(parent.children) do
                            if ch.key == child_key then
                                return {{i_start[1]-1, parent_i}, index_end}
                            end
                        end
                    end
                    error("Parent not found in previous layer, INVALID GRAPH")

                else
                    return {index_start, index_end}
                end
            end

        end

    else
        -- We have an edge selected between two nodes
        if dir == 'h' then
            return {index_start, vim.deepcopy(index_start)}
        end
        if dir == 'l' then
            return {index_end, vim.deepcopy(index_end)}
        end
        if dir == 'j' or dir == 'k' then
            local parent = key_to_node[layer_to_node_keys[index_start[1]][index_start[2]]]
            get_next(dir, i_end)

            if is_out_of_bounds(i_end) then
                return {index_start, index_end}
            end
            local candidate_end_key = layer_to_node_keys[i_end[1]][i_end[2]]

            while not g.has_child_with_key(parent, candidate_end_key) do
                get_next(dir, i_end)
                if is_out_of_bounds(i_end) then
                    return {index_start, index_end}
                end
                candidate_end_key = layer_to_node_keys[i_end[1]][i_end[2]]
            end

            return {index_start, i_end}


        end
    end

    error("Unexpected direction: " .. dir)

end

return MV
