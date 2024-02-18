describe("ascii_graph", function()
    local ag = require('trails.ascii_graph')

    it("can count crossings", function()
        assert.equals(0, ag.is_crossing(1, 1, 2, 2))
        assert.equals(1, ag.is_crossing(1, 2, 2, 1))
        assert.equals(1, ag.is_crossing(2, 1, 1, 2))
        assert.equals(1, ag.is_crossing(1, 2, 2, 3))
        assert.equals(1, ag.is_crossing(2, 3, 1, 2))
        assert.equals(0, ag.is_crossing(1, 3, 4, 6))
        assert.equals(0, ag.is_crossing(1, 3, 6, 4))
        assert.equals(1, ag.is_crossing(1, 3, 6, 2))

        -- When starting/ending in the same node there is no crossing, they get connected
        assert.equals(0, ag.is_crossing(1, 3, 6, 3))
        assert.equals(0, ag.is_crossing(9, 4, 1, 4))
        assert.equals(0, ag.is_crossing(1, 1, 1, 1))
        assert.equals(0, ag.is_crossing(1, 1, 1, 4))
        assert.equals(0, ag.is_crossing(1, 3, 1, 4))
        assert.equals(0, ag.is_crossing(1, 9, 1, 4))
    end)

    it("can count crossings between two layers", function()
        local nodea1 = { key = "nodea1key", children = {}}
        local nodea2 = { key = "nodea2key", children = {nodea1}}

        local key_to_node = {}
        key_to_node.nodea1key = nodea1
        key_to_node.nodea2key = nodea2

        local layer_to_node_keys = {}
        layer_to_node_keys[1] = {nodea2.key}
        layer_to_node_keys[2] = {nodea1.key}

        assert.equals(0, ag.count_crossings(key_to_node, layer_to_node_keys))

        local nodeb1 = { key = "nodeb1key", children = {}}
        local nodeb2 = { key = "nodeb2key", children = {nodeb1}}

        key_to_node.nodeb1key = nodeb1
        key_to_node.nodeb2key = nodeb2

        layer_to_node_keys[1] = {nodea2.key, nodeb2.key}
        layer_to_node_keys[2] = {nodeb1.key, nodea1.key}

        assert.equals(1, ag.count_crossings(key_to_node, layer_to_node_keys))
    end)

    it("can count crossings between multiple layers", function()
        -- A1   B1   A3
        --      A2   B2
        local nodea1 = { key = "nodea1key", children = {}}
        local nodea2 = { key = "nodea2key", children = {}}
        local nodea3 = { key = "nodea3key", children = {}}
        nodea1.children = { nodea2 }
        nodea2.children = { nodea3 }
        local nodeb1 = { key = "nodeb1key", children = {}}
        local nodeb2 = { key = "nodeb2key", children = {}}
        nodeb1.children = { nodeb2 }

        local key_to_node = {}
        key_to_node[nodea1.key] = nodea1
        key_to_node[nodea2.key] = nodea2
        key_to_node[nodea3.key] = nodea3
        key_to_node[nodeb1.key] = nodeb1
        key_to_node[nodeb2.key] = nodeb2

        local layer_to_node_keys = {}
        layer_to_node_keys[1] = {nodea1.key}
        layer_to_node_keys[2] = {nodeb1.key, nodea2.key}
        layer_to_node_keys[3] = {nodea3.key, nodeb2.key}

        assert.equals(1, ag.count_crossings(key_to_node, layer_to_node_keys))
    end)

    it("can count crossings between multiple layers2", function()
        -- A1   B1   A3   B3
        --      A2   B2   A4
        local nodea1 = { key = "nodea1key", children = {}}
        local nodea2 = { key = "nodea2key", children = {}}
        local nodea3 = { key = "nodea3key", children = {}}
        local nodea4 = { key = "nodea4key", children = {}}
        nodea1.children = { nodea2 }
        nodea2.children = { nodea3 }
        nodea3.children = { nodea4 }
        local nodeb1 = { key = "nodeb1key", children = {}}
        local nodeb2 = { key = "nodeb2key", children = {}}
        local nodeb3 = { key = "nodeb3key", children = {}}
        nodeb1.children = { nodeb2 }
        nodeb2.children = { nodeb3 }

        local key_to_node = {}
        key_to_node[nodea1.key] = nodea1
        key_to_node[nodea2.key] = nodea2
        key_to_node[nodea3.key] = nodea3
        key_to_node[nodea4.key] = nodea4
        key_to_node[nodeb1.key] = nodeb1
        key_to_node[nodeb2.key] = nodeb2
        key_to_node[nodeb3.key] = nodeb3

        local layer_to_node_keys = {}
        layer_to_node_keys[1] = {nodea1.key}
        layer_to_node_keys[2] = {nodeb1.key, nodea2.key}
        layer_to_node_keys[3] = {nodea3.key, nodeb2.key}
        layer_to_node_keys[4] = {nodeb3.key, nodea4.key}

        assert.equals(2, ag.count_crossings(key_to_node, layer_to_node_keys))
    end)

    it("can count crossings between multiple layers with multiple nodes in layer", function()
        -- A1   B1   A3   B3
        --      A2   B2   C3
        --      C1   C2   A4
        local nodea1 = { key = "nodea1key", children = {}}
        local nodea2 = { key = "nodea2key", children = {}}
        local nodea3 = { key = "nodea3key", children = {}}
        local nodea4 = { key = "nodea4key", children = {}}
        nodea1.children = { nodea2 }
        nodea2.children = { nodea3 }
        nodea3.children = { nodea4 }
        local nodeb1 = { key = "nodeb1key", children = {}}
        local nodeb2 = { key = "nodeb2key", children = {}}
        local nodeb3 = { key = "nodeb3key", children = {}}
        nodeb1.children = { nodeb2 }
        nodeb2.children = { nodeb3 }

        local nodec1 = { key = "nodec1key", children = {}}
        local nodec2 = { key = "nodec2key", children = {}}
        local nodec3 = { key = "nodec3key", children = {}}
        nodec1.children = { nodec2 }
        nodec2.children = { nodec3 }

        local key_to_node = {}
        key_to_node[nodea1.key] = nodea1
        key_to_node[nodea2.key] = nodea2
        key_to_node[nodea3.key] = nodea3
        key_to_node[nodea4.key] = nodea4
        key_to_node[nodeb1.key] = nodeb1
        key_to_node[nodeb2.key] = nodeb2
        key_to_node[nodeb3.key] = nodeb3
        key_to_node[nodec1.key] = nodec1
        key_to_node[nodec2.key] = nodec2
        key_to_node[nodec3.key] = nodec3

        local layer_to_node_keys = {}
        layer_to_node_keys[1] = {nodea1.key}
        layer_to_node_keys[2] = {nodeb1.key, nodea2.key, nodec1.key}
        layer_to_node_keys[3] = {nodea3.key, nodeb2.key, nodec2.key}
        layer_to_node_keys[4] = {nodeb3.key, nodec3.key, nodea4.key}

        assert.equals(4, ag.count_crossings(key_to_node, layer_to_node_keys))
    end)
end)
