import 'package:flutter/widgets.dart';

import '../../model/enums/dfs_order.dart';
import '../graph.dart';

List<String> dfs(Graph g, List<String> vs,DFSOrder order) {
  var navigation = (g.isDirected ? g.successors : g.neighbors);

  ///nodeId
  List<String> acc = [];

  ///存储已遍历过的nodeId
  Map<String, bool> visited = {};

  for (var v in vs) {
    if (!g.hasNode(v)) {
      throw FlutterError("Graph does not have node: $v");
    }
    doDfs(g, v, order ==DFSOrder.post, visited, navigation, acc);
  }
  return acc;
}

void doDfs(Graph g, String v, bool postorder, Map<String, bool> visited, navigation, List<String> acc) {
  if (!visited.containsKey(v)) {
    visited[v] = true;
    if (!postorder) {
      acc.add(v);
    }
    navigation(v).forEach((w) {
      doDfs(g, w, postorder, visited, navigation, acc);
    });
    if (postorder) {
      acc.add(v);
    }
  }
}
