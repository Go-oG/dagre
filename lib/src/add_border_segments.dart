import 'package:dart_dagre/src/graph/graph.dart';
import 'package:dart_dagre/src/model/enums/dummy.dart';
import 'package:dart_dagre/src/util.dart';

import 'model/props.dart';

void addBorderSegments(Graph g) {
  dfs(String v) {
    var children = g.children(v);
    var node = g.node(v);
    if (children!=null) {
      children.forEach(dfs);
    }
    if (node.hasOwn(minRankK)) {
      node[borderLeftK] = [];
      node[borderRightK] = [];
      for (var rank = node.getI(minRankK), maxRank = node.getI(maxRankK) + 1; rank < maxRank; ++rank) {
        _addBorderNode(g, "borderLeft", "_bl", v, node, rank);
        _addBorderNode(g, "borderRight", "_br", v, node, rank);
      }
    }
  }
  g.children()?.forEach(dfs);
}

void _addBorderNode(Graph g, String prop, String prefix, String sg, Props sgNode, int rank) {
  var label = Props();
  label[widthK] = 0;
  label[heightK] = 0;
  label[rankK] = rank;
  label[borderTypeK] = prop;

  List<String> bl = prop == 'borderLeft' ? sgNode[borderLeftK] : sgNode[borderRightK];

  var prev = (rank - 1 < bl.length ? bl[rank - 1] : null);
  var curr = addDummyNode(g, Dummy.border, label, prefix);
  bl[rank] = curr;
  g.setParent(curr, sg);
  if (prev != null) {
    g.setEdge2(prev, curr, value:{weightK:1}.toProps);
  }
}
