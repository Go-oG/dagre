import 'package:dart_dagre/src/model/edge_props.dart';
import 'package:dart_dagre/src/model/node_props.dart';
import 'package:dart_dagre/src/rank/util.dart';
import '../graph/graph.dart';
import '../util/list_util.dart';

Graph feasibleTree(Graph g) {
  var t = Graph(isDirected: false);
  var start = g.nodes[0];
  var size = g.nodeCount;
  t.setNode(start, NodeProps());
  EdgeObj edge;
  num delta;
  while (tightTree(t, g) < size) {
    edge = _findMinSlackEdge(t, g);
    delta = t.hasNode(edge.v) ? slack(g, edge) : -slack(g, edge);
    _shiftRanks(t, g, delta);
  }
  return t;
}

int tightTree(Graph t, Graph g) {
  dfs(String v) {
    g.nodeEdges(v).forEach((e) {
      var edgeV = e.v, w = (v == edgeV) ? e.w : edgeV;
      if (!t.hasNode(w) && slack(g, e) != 0) {
        t.setNode(w, NodeProps());
        t.setEdge(v, w, value:EdgeProps.zero());
        dfs(w);
      }
    });
  }

  t.nodes.forEach(dfs);
  return t.nodeCount;
}

EdgeObj _findMinSlackEdge(Graph t, Graph g) {
  var edges = g.edges;

  List<dynamic> acc = [double.infinity, null];
  for (var edge in edges) {
    double edgeSlack = double.infinity;
    if (t.hasNode(edge.v) != t.hasNode(edge.w)) {
      edgeSlack = slack(g, edge);
    }
    if (edgeSlack < acc[0]) {
      acc = [edgeSlack, edge];
      continue;
    }
  }
  return acc[1];
}

void _shiftRanks(Graph t, Graph g, num delta) {
  for (var v in t.nodes) {
    var rank = (g.node<NodeProps>(v).rank ?? 0) + delta;
    g.node(v).rank = rank.toInt();
  }
}
