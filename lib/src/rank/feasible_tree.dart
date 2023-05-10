import 'package:dart_dagre/src/model/edge.dart';
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
  Edge edge;
  num delta;
  while (tightTree(t, g) < size) {
    edge = _findMinSlackEdge(t, g);
    delta = t.hasNode(edge.v) ? slack(g, edge) : -slack(g, edge);
    _shiftRanks(t, g, delta);
  }
  return t;
}

int tightTree(Graph t, Graph g) {
  dfs(v) {
    g.nodeEdges(v).forEach((e) {
      var edgeV = e.v, w = (v == edgeV) ? e.w : edgeV;
      if (!t.hasNode(w) && slack(g, e)==0) {
        t.setNode(w, NodeProps());
        t.setEdge(v, w, value:EdgeProps.zero());
        dfs(w);
      }
    });
  }

  t.nodes.forEach(dfs);
  return t.nodeCount;
}

Edge _findMinSlackEdge(Graph t, Graph g) {
  return minBy(g.edges, (e) {
    if (t.hasNode(e.v) != t.hasNode(e.w)) {
      return slack(g, e);
    }
    return null;
  });
}

void _shiftRanks(Graph t, Graph g, num delta) {
  for (var v in t.nodes) {
    g.node(v).rank = (g.node(v).rank + delta).toInt();
  }
}
