import 'package:dart_dagre/src/model/props.dart';

import '../graph/graph.dart';
import '../util/list_util.dart';

Graph longestPath(Graph g) {
  Map<String, bool> visited = {};

  double dfs(String v) {
    var label = g.node(v);
    if (visited.containsKey(v)) {
      return label.getD(rankK);
    }
    visited[v] = true;

    var outEdgesMinLens = g.outEdges(v)!.map((e) {
      return dfs(e.w) - g.edge2(e).getD(minLenK);
    });
    double? rankValue = min(outEdgesMinLens)?.toDouble();

    rankValue ??= double.infinity;
    if (rankValue.isInfinite || rankValue.isNaN) {
      rankValue = 0;
    }
    label[rankK] = rankValue;
    return rankValue;
  }

  for (var s in g.sources) {
    dfs(s);
  }
  return g;
}

double slack(Graph g, Edge e) {
  var r1 = g.node(e.w).getD(rankK);
  var r2 = g.node(e.v).getD(rankK);
  return r1 - r2 - g.edge2(e).getD(minLenK);
}
