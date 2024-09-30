describe("ascii_graph", function()
    local g = require('trails.graph')

    it("can count crossings", function()
        assert.equals(0, g.is_crossing(1, 1, 2, 2))
        assert.equals(1, g.is_crossing(1, 2, 2, 1))
        assert.equals(1, g.is_crossing(2, 1, 1, 2))
        assert.equals(0, g.is_crossing(1, 2, 2, 3))
        assert.equals(0, g.is_crossing(2, 3, 1, 2))
        assert.equals(0, g.is_crossing(1, 3, 4, 6))
        assert.equals(0, g.is_crossing(1, 3, 6, 4))
        assert.equals(1, g.is_crossing(1, 3, 6, 2))

        -- When starting/ending in the same node there is no crossing, they get connected
        assert.equals(0, g.is_crossing(1, 3, 6, 3))
        assert.equals(0, g.is_crossing(9, 4, 1, 4))
        assert.equals(0, g.is_crossing(1, 1, 1, 1))
        assert.equals(0, g.is_crossing(1, 1, 1, 4))
        assert.equals(0, g.is_crossing(1, 3, 1, 4))
        assert.equals(0, g.is_crossing(1, 9, 1, 4))
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

        assert.equals(0, g.count_crossings(key_to_node, layer_to_node_keys))

        local nodeb1 = { key = "nodeb1key", children = {}}
        local nodeb2 = { key = "nodeb2key", children = {nodeb1}}

        key_to_node.nodeb1key = nodeb1
        key_to_node.nodeb2key = nodeb2

        layer_to_node_keys[1] = {nodea2.key, nodeb2.key}
        layer_to_node_keys[2] = {nodeb1.key, nodea1.key}

        assert.equals(1, g.count_crossings(key_to_node, layer_to_node_keys))
    end)

    it("can count crossings between multiple layers", function()
        -- A1   B1   A3
        --      A2   B2
        local nodea1 = { name = "nodea1", key = "nodea1key", children = {}, expanded = true}
        local nodea2 = { name = "nodea2", key = "nodea2key", children = {}, expanded = true}
        local nodea3 = { name = "nodea3", key = "nodea3key", children = {}, expanded = true}
        local nodeb1 = { name = "nodeb1", key = "nodeb1key", children = {}, expanded = true}
        local nodeb2 = { name = "nodeb2", key = "nodeb2key", children = {}, expanded = true}
        nodea1.children = { nodea2, nodeb1 }
        nodea2.children = { nodea3 }
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

        assert.equals(1, g.count_crossings(key_to_node, layer_to_node_keys))
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

        assert.equals(2, g.count_crossings(key_to_node, layer_to_node_keys))
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

        assert.equals(3, g.count_crossings(key_to_node, layer_to_node_keys))
    end)

    it("can count crossings", function()
        -- A1   B1   A3
        --      A2   B2
        local nodea1 = { key = "nodea1key", children = {}}
        local nodea2 = { key = "nodea2key", children = {}}
        local nodea3 = { key = "nodea3key", children = {}}
        local nodeb1 = { key = "nodeb1key", children = {}}
        local nodeb2 = { key = "nodeb2key", children = {}}
        local nodeE = { name = "", key = "empty", children = {}, expanded = true}
        nodea1.children = { nodeb1, nodea2 }
        nodea2.children = { nodea3 }
        nodeb1.children = { nodeb2 }

        local key_to_node = {}
        key_to_node[nodea1.key] = nodea1
        key_to_node[nodea2.key] = nodea2
        key_to_node[nodea3.key] = nodea3
        key_to_node[nodeb1.key] = nodeb1
        key_to_node[nodeb2.key] = nodeb2
        key_to_node[nodeE.key] = nodeE

        local layer_to_node_keys = {}
        layer_to_node_keys[1] = {nodea1.key}
        layer_to_node_keys[2] = {nodeb1.key, nodea2.key}
        layer_to_node_keys[3] = {nodea3.key, nodeE.key, nodeE.key, nodeb2.key}

        assert.equals(1, g.count_crossings(key_to_node, layer_to_node_keys))
    end)

    it("can count crossings between multiple layers with multiple nodes in layer 2", function()
        -- five   six   three   two   main
        --        five2         t2
        --                      one
        --              five3
        local five = { key = "fivekey", children = {}}
        local fiveCon = { key = "fiveConkey", children = {}}
        local fiveConCon = { key = "fiveConConkey", children = {}}
        local six = { key = "sixkey", children = {}}
        local three = { key = "threekey", children = {}}
        local two = { key = "twokey", children = {}}
        local t2 = { key = "t2key", children = {}}
        local one = { key = "onekey", children = {}}
        local main = { key = "mainkey", children = {}}
        five.children = { six, fiveCon }
        fiveCon.children = { fiveConCon }
        fiveConCon.children = { t2 }
        six.children = { three }
        three.children = { two, t2, one }
        two.children = { main }
        t2.children = { main }
        one.children = { main }
        local nodeE = { name = "", key = "empty", children = {}, expanded = true}

        local key_to_node = {}
        key_to_node[five.key] = five
        key_to_node[fiveCon.key] = fiveCon
        key_to_node[fiveConCon.key] = fiveConCon
        key_to_node[six.key] = six
        key_to_node[three.key] = three
        key_to_node[two.key] = two
        key_to_node[t2.key] = t2
        key_to_node[one.key] = one
        key_to_node[main.key] = main
        key_to_node[nodeE.key] = nodeE

        local layer_to_node_keys = {}
        layer_to_node_keys[1] = {five.key}
        layer_to_node_keys[2] = {six.key, fiveCon.key}
        layer_to_node_keys[3] = {three.key, nodeE.key, nodeE.key, fiveConCon.key}
        layer_to_node_keys[4] = {two.key, t2.key, one.key}
        layer_to_node_keys[5] = {main.key}

        assert.equals(1, g.count_crossings(key_to_node, layer_to_node_keys))
    end)

    it ("doesn't add connection nodes when they are not needed", function()
        local nodea1 = { name = "nodea1", key = "nodea1key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodea2 = { name = "nodea2", key = "nodea2key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodea3 = { name = "nodea3", key = "nodea3key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodeb2 = { name = "nodeb2", key = "nodeb2key", children = {}, expanded = false, type = g.NodeType.Regular}
        nodea1.children = { nodea2, nodeb2 }
        nodea2.children = { nodea3 }
        nodeb2.children = { nodea3 }

        local key_to_node = {}
        key_to_node[nodea1.key] = nodea1
        key_to_node[nodea2.key] = nodea2
        key_to_node[nodea3.key] = nodea3
        key_to_node[nodeb2.key] = nodeb2

        local layer_to_node_keys = {}
        layer_to_node_keys[1] = {nodea1.key}
        layer_to_node_keys[2] = {nodea2.key, nodeb2.key}
        layer_to_node_keys[3] = {nodea3.key}

        local expected_result = vim.deepcopy(layer_to_node_keys)

        g._add_connection_nodes(key_to_node, layer_to_node_keys)

        assert.are.same(expected_result, layer_to_node_keys)
    end)

    it ("creates multiple connection nodes from single parent when needed", function()
        local nodea1 = { name = "nodea1", key = "nodea1key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodea2 = { name = "nodea2", key = "nodea2key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodea3 = { name = "nodea3", key = "nodea3key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodeb3 = { name = "nodeb3", key = "nodeb3key", children = {}, expanded = true, type = g.NodeType.Regular}
        nodea1.children = { nodea3, nodeb3 }
        nodea2.children = { nodea3, nodeb3 }

        local key_to_node = {}
        key_to_node[nodea1.key] = nodea1
        key_to_node[nodea2.key] = nodea2
        key_to_node[nodea3.key] = nodea3
        key_to_node[nodeb3.key] = nodeb3

        local layer_to_node_keys = {}
        layer_to_node_keys[1] = {nodea1.key}
        layer_to_node_keys[2] = {nodea2.key}
        layer_to_node_keys[3] = {nodea3.key, nodeb3.key}

        local expected_result = vim.deepcopy(layer_to_node_keys)
        expected_result[2] = {nodea2.key, "nodea1key->nodea3key", "nodea1key->nodeb3key"}

        g._add_connection_nodes(key_to_node, layer_to_node_keys)

        assert.are.same(expected_result, layer_to_node_keys)

        local con_node1 = key_to_node["nodea1key->nodea3key"]
        assert.are.same("nodea3key", con_node1.connecting_to)
        assert.are.same("nodea1key", con_node1.connecting_from)

        local con_node2 = key_to_node["nodea1key->nodeb3key"]
        assert.are.same("nodeb3key", con_node2.connecting_to)
        assert.are.same("nodea1key", con_node2.connecting_from)
    end)

    it ("creates multiple connecting connection nodes when needed", function()
        local nodea1 = { name = "nodea1", key = "nodea1key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodea3 = { name = "nodea3", key = "nodea3key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodeb2 = { name = "nodeb2", key = "nodeb2key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodeb3 = { name = "nodeb3", key = "nodeb3key", children = {}, expanded = true, type = g.NodeType.Regular}
        nodea1.children = { nodea3 }
        nodeb2.children = { nodea3 }
        nodeb3.children = { nodea3 }

        local key_to_node = {}
        key_to_node[nodea1.key] = nodea1
        key_to_node[nodeb2.key] = nodeb2
        key_to_node[nodea3.key] = nodea3
        key_to_node[nodeb3.key] = nodeb3

        local layer_to_node_keys = {}
        layer_to_node_keys[1] = {nodea1.key}
        layer_to_node_keys[2] = {nodeb2.key}
        layer_to_node_keys[3] = {nodeb3.key}
        layer_to_node_keys[4] = {nodea3.key}

        local expected_result = vim.deepcopy(layer_to_node_keys)
        expected_result[2] = {nodeb2.key, "nodea1key->nodea3key"}
        expected_result[3] = {nodeb3.key, "nodeb2key->nodea3key", "nodea1key->nodea3key->nodea3key"}

        g._add_connection_nodes(key_to_node, layer_to_node_keys)

        assert.are.same(expected_result, layer_to_node_keys)

        local con_node1 = key_to_node["nodea1key->nodea3key->nodea3key"]
        assert.are.same("nodea3key", con_node1.connecting_to)
        assert.are.same("nodea1key", con_node1.connecting_from)
    end)

    it ("assigns layers to simple graph", function()
        local nodea1 = { name = "nodea1", key = "nodea1key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodea2 = { name = "nodea2", key = "nodea2key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodea3 = { name = "nodea3", key = "nodea3key", children = {}, expanded = true, type = g.NodeType.Regular}
        nodea1.children = { nodea2 }
        nodea2.children = { nodea3 }

        local key_to_node = {}
        key_to_node[nodea1.key] = nodea1
        key_to_node[nodea2.key] = nodea2
        key_to_node[nodea3.key] = nodea3

        local expected_result = {}
        expected_result[nodea1.key] = 1
        expected_result[nodea2.key] = 2
        expected_result[nodea3.key] = 3

        local layer_to_node_keys = g._assign_nodes_to_layers(nodea1, key_to_node)

        assert.are.same(expected_result, layer_to_node_keys)
    end)

    it ("assigns layers to a simple graph with loop", function()
        local nodea1 = { name = "nodea1", key = "nodea1key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodea2 = { name = "nodea2", key = "nodea2key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodea3 = { name = "nodea3", key = "nodea3key", children = {}, expanded = true, type = g.NodeType.Regular}
        nodea1.children = { nodea2 }
        nodea2.children = { nodea3 }
        nodea3.children = { nodea1 }

        local key_to_node = {}
        key_to_node[nodea1.key] = nodea1
        key_to_node[nodea2.key] = nodea2
        key_to_node[nodea3.key] = nodea3

        local expected_result = {}
        expected_result[nodea1.key] = 1
        expected_result[nodea2.key] = 2
        expected_result[nodea3.key] = 3

        local layer_to_node_keys = g._assign_nodes_to_layers(nodea1, key_to_node)

        assert.are.same(expected_result, layer_to_node_keys)
    end)

    it ("assigns layers to a simple graph with loop 2", function()
        local nodea1 = { name = "nodea1", key = "nodea1key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodea2 = { name = "nodea2", key = "nodea2key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodea3 = { name = "nodea3", key = "nodea3key", children = {}, expanded = true, type = g.NodeType.Regular}
        nodea1.children = { nodea2 }
        nodea2.children = { nodea3 }
        nodea3.children = { nodea2 }

        local key_to_node = {}
        key_to_node[nodea1.key] = nodea1
        key_to_node[nodea2.key] = nodea2
        key_to_node[nodea3.key] = nodea3

        local expected_result = {}
        expected_result[nodea1.key] = 1
        expected_result[nodea2.key] = 4
        expected_result[nodea3.key] = 3

        local node_to_layer = g._assign_nodes_to_layers(nodea1, key_to_node)
        local layer_to_node_keys = g._transform_to_layers(key_to_node, node_to_layer)

        assert.are.same(expected_result, node_to_layer)

        local expected_layer_to_node_keys = {}
        expected_layer_to_node_keys[1] = {nodea1.key}
        expected_layer_to_node_keys[2] = {nodea3.key}
        expected_layer_to_node_keys[3] = {nodea2.key}

        assert.are.same(expected_layer_to_node_keys, layer_to_node_keys)
    end)
end)
