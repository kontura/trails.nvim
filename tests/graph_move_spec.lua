describe("graph_move", function()
    local mv = require('trails.graph_move')
    local g = require('trails.graph')

    it("can move up/down to node", function()
        local nodea1 = { name = "nodea1", key = "nodea1key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodea2 = { name = "nodea2", key = "nodea2key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodea3 = { name = "nodea3", key = "nodea3key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodeE = { name = "", key = "empty", children = {}, expanded = true, type = g.NodeType.Empty}

        local key_to_node = {}
        key_to_node[nodea1.key] = nodea1
        key_to_node[nodea2.key] = nodea2
        key_to_node[nodea3.key] = nodea3
        key_to_node[nodeE.key] = nodeE

        local layer_to_node_keys = {}
        layer_to_node_keys[1] = {nodea1.key, nodea2.key, nodea3.key}

        assert.are.same({{1,2}, {1,2}}, mv.graph_move(layer_to_node_keys, key_to_node, 'j', {1,1}, {1,1}))
        assert.are.same({{1,3}, {1,3}}, mv.graph_move(layer_to_node_keys, key_to_node, 'j', {1,2}, {1,2}))
        assert.are.same({{1,2}, {1,2}}, mv.graph_move(layer_to_node_keys, key_to_node, 'k', {1,3}, {1,3}))
        assert.are.same({{1,3}, {1,3}}, mv.graph_move(layer_to_node_keys, key_to_node, 'j', {1,3}, {1,3}))
        assert.are.same({{1,1}, {1,1}}, mv.graph_move(layer_to_node_keys, key_to_node, 'k', {1,1}, {1,1}))

        layer_to_node_keys[1] = {nodea1.key, nodeE.key, nodea3.key}
        assert.are.same({{1,3}, {1,3}}, mv.graph_move(layer_to_node_keys, key_to_node, 'j', {1,1}, {1,1}))

        layer_to_node_keys[1] = {nodea1.key, nodeE.key}
        assert.are.same({{1,1}, {1,1}}, mv.graph_move(layer_to_node_keys, key_to_node, 'j', {1,1}, {1,1}))
    end)

    it("can move to the next/previous", function()
        local nodea1 = { name = "nodea1", key = "nodea1key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodea2 = { name = "nodea2", key = "nodea2key", children = {}, expanded = true, type = g.NodeType.Regular}
        nodea1.children = { nodea2 }

        local key_to_node = {}
        key_to_node[nodea1.key] = nodea1
        key_to_node[nodea2.key] = nodea2

        local layer_to_node_keys = {}
        layer_to_node_keys[1] = {nodea1.key}
        layer_to_node_keys[2] = {nodea2.key}

        -- Node selected
        assert.are.same({{1,1}, {2,1}}, mv.graph_move(layer_to_node_keys, key_to_node, 'l', {1,1}, {1,1}))
        assert.are.same({{1,1}, {2,1}}, mv.graph_move(layer_to_node_keys, key_to_node, 'h', {2,1}, {2,1}))
        assert.are.same({{1,1}, {1,1}}, mv.graph_move(layer_to_node_keys, key_to_node, 'h', {1,1}, {1,1}))
        assert.are.same({{2,1}, {2,1}}, mv.graph_move(layer_to_node_keys, key_to_node, 'l', {2,1}, {2,1}))

        -- Edge selected
        assert.are.same({{2,1}, {2,1}}, mv.graph_move(layer_to_node_keys, key_to_node, 'l', {1,1}, {2,1}))
        assert.are.same({{1,1}, {1,1}}, mv.graph_move(layer_to_node_keys, key_to_node, 'h', {1,1}, {2,1}))
    end)

    it("can move up/down withing sibling edges", function()
        local nodea1 = { name = "nodea1", key = "nodea1key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodea2 = { name = "nodea2", key = "nodea2key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodea3 = { name = "nodea3", key = "nodea3key", children = {}, expanded = true, type = g.NodeType.Regular}
        nodea1.children = { nodea2, nodea3 }

        local key_to_node = {}
        key_to_node[nodea1.key] = nodea1
        key_to_node[nodea2.key] = nodea2
        key_to_node[nodea3.key] = nodea3

        local layer_to_node_keys = {}
        layer_to_node_keys[1] = {nodea1.key}
        layer_to_node_keys[2] = {nodea2.key, nodea3.key}

        assert.are.same({{1,1}, {2,2}}, mv.graph_move(layer_to_node_keys, key_to_node, 'j', {1,1}, {2,1}))
        assert.are.same({{1,1}, {2,1}}, mv.graph_move(layer_to_node_keys, key_to_node, 'k', {1,1}, {2,1}))
        assert.are.same({{1,1}, {2,1}}, mv.graph_move(layer_to_node_keys, key_to_node, 'k', {1,1}, {2,2}))
        assert.are.same({{1,1}, {2,2}}, mv.graph_move(layer_to_node_keys, key_to_node, 'j', {1,1}, {2,2}))
    end)

    it("automatically moves along connections edges", function()
    end)
end)
