import 'package:dart_dagre/src/model/edge_props.dart';

import '../graph/graph.dart';
import '../util/list_util.dart';

Graph longestPath(Graph g) {
  Map<String, bool> visited = {};
  dfs(v) {
    var label = g.node(v);
    if (visited.containsKey(v)) {
      return label.rank;
    }
    visited[v] = true;
    num? rank = min(g.outEdges(v).map((e) {
      return dfs(e.w) - g.edge2<EdgeProps>(e).minLen;
    }));
    if (rank == null || rank.isInfinite) {
      rank = 0;
    }
    label.rank = rank.toInt();
    return rank;
  }
  g.sources.forEach(dfs);
  return g;
}

num slack(Graph g, EdgeObj e) {
  return g.node(e.w).rank - g.node(e.v).rank - g.edge2<EdgeProps>(e).minLen;
}
