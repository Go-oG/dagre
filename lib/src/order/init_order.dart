import 'package:dart_dagre/src/model/props.dart';
import 'package:dart_dagre/src/util/list_util.dart';
import 'package:dart_dagre/src/util/util.dart';
import '../graph/graph.dart';

List<List<String>> initOrder(Graph g) {
  Map<String, bool> visited = {};
  var simpleNodes = g.nodes.filter((v) {
    var list=g.children(v);
    return list==null||list.isEmpty;
  });
  var maxRank = max<int>(simpleNodes.map2((v,i) {
    return g.node(v).getI(rankK);
  }))!;

  List<List<String>> layers = List.from(range(0, maxRank + 1).map<List<String>>((e) {
    return [];
  }));

  void dfs(String v) {
    if (visited.containsKey(v)) return;
    visited[v] = true;
    Props node = g.node(v);
    layers[node.getI(rankK)].add(v);
    g.successors(v)?.forEach(dfs);
  }

  var orderedVs =simpleNodes;
  orderedVs.sort((a, b) {
    return g.node(a).getD(rankK).compareTo(g.node(b).getD(rankK));
  });
  orderedVs.forEach(dfs);
  return layers;
}
