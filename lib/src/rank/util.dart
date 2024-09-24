import 'package:dart_dagre/src/model/edge_props.dart';
import 'package:dart_dagre/src/model/node_props.dart';

import '../graph/graph.dart';
import '../util/list_util.dart';

Graph longestPath(Graph g) {
  Map<String, bool> visited = {};

  double dfs(String v) {
    var label = g.node<NodeProps>(v);
    if (visited.containsKey(v)) {
      return label.rank!.toDouble();
    }
    visited[v] = true;
    double? rank = min(g.outEdges(v).map((e) {
      return dfs(e.w) - g.edge2<EdgeProps>(e).minLen;
    }))?.toDouble();
    rank ??= double.infinity;
    if (rank.isInfinite || rank.isNaN) {
      rank = 0;
    }
    label.rank = rank.toInt();

    return rank;
  }
  g.sources.forEach(dfs);
  return g;
}

double slack(Graph g, EdgeObj e) {
  var r1 = g.node<NodeProps>(e.w).rank!;
  var r2 = g.node<NodeProps>(e.v).rank!;
  return r1 - r2 - g.edge2<EdgeProps>(e).minLen;
}
