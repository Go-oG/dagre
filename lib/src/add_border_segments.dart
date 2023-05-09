import 'package:dagre/src/graph/graph.dart';
import 'package:dagre/src/model/enums/dummy.dart';
import 'package:dagre/src/model/edge_props.dart';
import 'package:dagre/src/model/node_props.dart';
import 'package:dagre/src/util.dart';

void addBorderSegments(Graph g) {
  dfs(v) {
    var children = g.children(v);
    var node = g.node(v);
    if (children.isNotEmpty) {
      children.forEach(dfs);
    }

    if (node.minRankNull != null) {
      node.borderLeft = [];
      node.borderRight = [];
      for (var rank = node.minRank, maxRank = node.maxRank + 1; rank < maxRank; ++rank) {
        _addBorderNode(g, "borderLeft", "_bl", v, node, rank);
        _addBorderNode(g, "borderRight", "_br", v, node, rank);
      }
    }
  }

  g.children().forEach(dfs);
}

void _addBorderNode(Graph g, String prop, String prefix, String sg, NodeProps sgNode, int rank) {
  var label = NodeProps();
  label.width = 0;
  label.height = 0;
  label.rank = rank;
  label.borderType = prop;

  List<String> bl = prop == 'borderLeft' ? sgNode.borderLeft : sgNode.borderRight;
  var prev = (rank - 1 < bl.length ? bl[rank - 1] : null);
  var curr = addDummyNode(g, Dummy.border, label, prefix);
  bl[rank] = curr;
  g.setParent(curr, sg);
  if (prev != null) {
    g.setEdge(prev, curr, value: EdgeProps(weight: 1));
  }
}
