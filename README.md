# Trails Neovim plugin doing call graphs

Inspired by now archived Sourcetrail.

- Requires set up LSP.
- It overrides the `callHierarchy/incomingCalls` handler to show an ascii art graph in a new buffer in the current window.

## Bindings
- Move around the graph with `h`, `j`, `k`, `l`.
- Jump to source of selected element with `gd`.
- Expand/Collaps toggle selected node with `za`.

![dropdown](https://i.imgur.com/r3ZkLHa.png)
