import 'package:dart_dagre/src/model/node_props.dart';
import 'package:dart_dagre/src/util/list_util.dart';
import 'package:dart_dagre/src/util/util.dart';
import '../graph/graph.dart';

List<List<String>> initOrder(Graph g) {
  Map<String, bool> visited = {};
  var simpleNodes = g.nodes.filter((v) {
    return g.children(v).isEmpty;
  });
  var maxRank = max<int>(simpleNodes.map2((v,i) {
    return g.node(v).rankNull;
  }))!;

  List<List<String>> layers = List.from(range(0, maxRank + 1).map<List<String>>((e) {
    return [];
  }));

  void dfs(String v) {
    if (visited.containsKey(v)) return;
    visited[v] = true;
    NodeProps node = g.node(v);
    layers[node.rank].add(v);
    g.successors(v).forEach(dfs);
  }

  var orderedVs = [...simpleNodes];
  orderedVs.sort((a, b) {
    return g.node(a).rank.compareTo(g.node(b).rank);
  });
  orderedVs.forEach(dfs);
  return layers;
}
