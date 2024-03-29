describe("ascii_graph", function()
    local ag = require('trails.ascii_graph')
    local g = require('trails.graph')

    it("can draw simple graph", function()
        local nodeE = { name = "", key = "empty", children = {}, expanded = true, type = g.NodeType.Empty}
        local nodea1 = { name = "nodea1", key = "nodea1key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodea2 = { name = "nodea2", key = "nodea2key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodea3 = { name = "nodea3", key = "nodea3key", children = {}, expanded = true, type = g.NodeType.Regular}
        nodea1.children = { nodea2, nodea3 }

        local key_to_node = {}
        key_to_node[nodea1.key] = nodea1
        key_to_node[nodea2.key] = nodea2
        key_to_node[nodea3.key] = nodea3
        key_to_node[nodeE.key] = nodeE

        local layer_to_node_keys = {}
        layer_to_node_keys[1] = {nodea1.key}
        layer_to_node_keys[2] = {nodea3.key, nodea2.key}

        local lines = {}
        lines[1] = '[nodea1]◄┬──[nodea3]'
        lines[2] = '         └┐'
        lines[3] = '          └─[nodea2]'

        assert.are.same(lines, ag.draw_graph(key_to_node, "none", "none", layer_to_node_keys))

        layer_to_node_keys = {}
        layer_to_node_keys[1] = {nodea1.key}
        layer_to_node_keys[2] = {nodeE.key, nodea3.key, nodeE.key, nodeE.key, nodea2.key}

        lines = {}
        lines[1] = '[nodea1]◄┐'
        lines[2] = '         └┐'
        lines[3] = '          └┬──────[nodea3]'
        lines[4] = '           └┐'
        lines[5] = '            └┐'
        lines[6] = '             └┐'
        lines[7] = '              └┐'
        lines[8] = '               └┐'
        lines[9] = '                └─[nodea2]'

        assert.are.same(lines, ag.draw_graph(key_to_node, "none", "none", layer_to_node_keys))
    end)

    it("can draw graph", function()
        -- A1   B1   A3
        --      A2   B2
        local nodeE = { name = "", key = "empty", children = {}, expanded = true, type = g.NodeType.Empty}
        local nodea1 = { name = "nodea1", key = "nodea1key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodea2 = { name = "nodea2", key = "nodea2key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodea3 = { name = "nodea3", key = "nodea3key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodeb1 = { name = "nodeb1", key = "nodeb1key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodeb2 = { name = "nodeb2", key = "nodeb2key", children = {}, expanded = true, type = g.NodeType.Regular}
        nodea1.children = { nodea2, nodeb1 }
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
        layer_to_node_keys[3] = {nodea3.key, nodeb2.key}

        local lines = {}
        lines[1] = '[nodea1]◄┬──[nodeb1]◄┐┌─[nodea3]'
        lines[2] = '         └┐          ├┤'
        lines[3] = '          └─[nodea2]◄┘└─[nodeb2]'

        assert.are.same(lines, ag.draw_graph(key_to_node, "none", "none", layer_to_node_keys))
    end)

    it("can draw graph 2", function()
        -- A1      A3
        --     A2  A4
        --         A5
        local nodeE = { name = "", key = "empty", children = {}, expanded = true, type = g.NodeType.Empty}
        local nodea1 = { name = "nodea1", key = "nodea1key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodea2 = { name = "nodea2", key = "nodea2key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodea3 = { name = "nodea3", key = "nodea3key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodea4 = { name = "nodea4", key = "nodea4key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodea5 = { name = "nodea5", key = "nodea5key", children = {}, expanded = true, type = g.NodeType.Regular}
        nodea1.children = { nodea2 }
        nodea2.children = { nodea3, nodea4, nodea5 }

        local key_to_node = {}
        key_to_node[nodea1.key] = nodea1
        key_to_node[nodea2.key] = nodea2
        key_to_node[nodea3.key] = nodea3
        key_to_node[nodea4.key] = nodea4
        key_to_node[nodea5.key] = nodea5
        key_to_node[nodeE.key] = nodeE

        local layer_to_node_keys = {}
        layer_to_node_keys[1] = {nodea1.key}
        layer_to_node_keys[2] = {nodeE.key, nodea2.key}
        layer_to_node_keys[3] = {nodea3.key, nodea4.key, nodea5.key}

        local lines = {}
        lines[1] = '[nodea1]◄┐            ┌─[nodea3]'
        lines[2] = '         └┐          ┌┘'
        lines[3] = '          └─[nodea2]◄┼──[nodea4]'
        lines[4] = '                     └┐'
        lines[5] = '                      └─[nodea5]'

        assert.are.same(lines, ag.draw_graph(key_to_node, "none", "none", layer_to_node_keys))
    end)

    it("can draw graph 3", function()
        -- A1      A3
        --     A2
        --     B1
        local nodeE = { name = "", key = "empty", children = {}, expanded = true, type = g.NodeType.Empty}
        local nodea1 = { name = "nodea1", key = "nodea1key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodea2 = { name = "nodea2", key = "nodea2key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodea3 = { name = "nodea3", key = "nodea3key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodeb1 = { name = "nodeb1", key = "nodeb1key", children = {}, expanded = true, type = g.NodeType.Regular}
        nodea1.children = { nodea2, nodeb1 }
        nodea2.children = { nodea3 }
        nodeb1.children = { nodea3 }

        local key_to_node = {}
        key_to_node[nodea1.key] = nodea1
        key_to_node[nodea2.key] = nodea2
        key_to_node[nodea3.key] = nodea3
        key_to_node[nodeb1.key] = nodeb1
        key_to_node[nodeE.key] = nodeE

        local layer_to_node_keys = {}
        layer_to_node_keys[1] = {nodea1.key}
        layer_to_node_keys[2] = {nodeE.key, nodeE.key, nodea2.key, nodeE.key, nodeb1.key}
        layer_to_node_keys[3] = {nodea3.key}

        local lines = {}
        lines[1] = '[nodea1]◄┐                    ┌───┬─[nodea3]'
        lines[2] = '         └┐                  ┌┘  ┌┘'
        lines[3] = '          └┐                ┌┘  ┌┘'
        lines[4] = '           └┐              ┌┘  ┌┘'
        lines[5] = '            └┬────[nodea2]◄┘  ┌┘'
        lines[6] = '             └┐              ┌┘'
        lines[7] = '              └┐            ┌┘'
        lines[8] = '               └┐          ┌┘'
        lines[9] = '                └─[nodeb1]◄┘'

        assert.are.same(lines, ag.draw_graph(key_to_node, "none", "none", layer_to_node_keys))
    end)

    it("correcly draws a graph with nodes that are not expanded but have children", function()
        local nodeE = { name = "", key = "empty", children = {}, expanded = true, type = g.NodeType.Empty}
        local nodea1 = { name = "nodea1", key = "nodea1key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodea2 = { name = "nodea2", key = "nodea2key", children = {}, expanded = false, type = g.NodeType.Regular}
        local nodea3 = { name = "nodea3", key = "nodea3key", children = {}, expanded = true, type = g.NodeType.Regular}
        nodea1.children = { nodea2 }
        nodea2.children = { nodea3 }

        local key_to_node = {}
        key_to_node[nodea1.key] = nodea1
        key_to_node[nodea2.key] = nodea2
        key_to_node[nodea3.key] = nodea3
        key_to_node[nodeE.key] = nodeE

        local layer_to_node_keys = {}
        layer_to_node_keys[1] = {nodea1.key}
        layer_to_node_keys[2] = {nodea2.key}

        local lines = {}
        lines[1] = '[nodea1]◄──[nodea2]'

        assert.are.same(lines, ag.draw_graph(key_to_node, "none", "none", layer_to_node_keys))
    end)

    it("correcly draws a graph with nodes that are not expanded but have children 2", function()
        local nodeE = { name = "", key = "empty", children = {}, expanded = true, type = g.NodeType.Empty}
        local nodea1 = { name = "nodea1", key = "nodea1key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodea2 = { name = "nodea2", key = "nodea2key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodea3 = { name = "nodea3", key = "nodea3key", children = {}, expanded = true, type = g.NodeType.Regular}
        local nodeb2 = { name = "nodeb2", key = "nodeb2key", children = {}, expanded = false, type = g.NodeType.Regular}
        local nodeb3 = { name = "nodeb3", key = "nodeb3key", children = {}, expanded = true, type = g.NodeType.Regular}
        nodea1.children = { nodea2, nodeb2 }
        nodea2.children = { nodea3 }
        nodeb2.children = { nodeb3 }

        local key_to_node = {}
        key_to_node[nodea1.key] = nodea1
        key_to_node[nodea2.key] = nodea2
        key_to_node[nodea3.key] = nodea3
        key_to_node[nodeb2.key] = nodeb2
        key_to_node[nodeb3.key] = nodeb3
        key_to_node[nodeE.key] = nodeE

        local layer_to_node_keys = {}
        layer_to_node_keys[1] = {nodea1.key}
        layer_to_node_keys[2] = {nodea2.key, nodeb2.key}
        layer_to_node_keys[3] = {nodea3.key}

        local lines = {}
        lines[1] = '[nodea1]◄┬──[nodea2]◄──[nodea3]'
        lines[2] = '         └┐'
        lines[3] = '          └─[nodeb2]'

        assert.are.same(lines, ag.draw_graph(key_to_node, "none", "none", layer_to_node_keys))
    end)


    it("doesn't dras a connection for non-expanded edge even if one of its children is in next layer", function()
        local nodeE = { name = "", key = "empty", children = {}, expanded = true, type = g.NodeType.Empty}
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
        key_to_node[nodeE.key] = nodeE

        local layer_to_node_keys = {}
        layer_to_node_keys[1] = {nodea1.key}
        layer_to_node_keys[2] = {nodea2.key, nodeb2.key}
        layer_to_node_keys[3] = {nodea3.key}

        local lines = {}
        lines[1] = '[nodea1]◄┬──[nodea2]◄───[nodea3]'
        lines[2] = '         └┐'
        lines[3] = '          └─[nodeb2]'

        assert.are.same(lines, ag.draw_graph(key_to_node, "none", "none", layer_to_node_keys))
    end)
end)
