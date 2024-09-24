import 'package:dart_dagre/src/model/edge_props.dart';
import 'package:dart_dagre/src/model/node_props.dart';
import 'package:dart_dagre/src/rank/util.dart';
import 'package:dart_dagre/src/util/list_util.dart';
import '../graph/graph.dart';
import '../graph/alg/postorder.dart';
import '../graph/alg/preorder.dart';
import '../util.dart' as util;
import 'feasible_tree.dart';

void networkSimplex(Graph g) {
  var g2 = util.simplify(g);
  longestPath(g2);
  var t = feasibleTree(g2);
  _initLowLimValues(t);
  _initCutValues(t, g2);
  EdgeObj? e;
  EdgeObj f;
  while ((e = leaveEdge(t)) != null) {
    f = _enterEdge(t, g2, e!);
    _exchangeEdges(t, g2, e, f);
  }

  // for(var v in g2.nodes){
  //   var np = g2.node<NodeProps>(v);
  //   var np2 = g.node<NodeProps>(v);
  //   np2.rank=np.rank;
  // }
}

void _initCutValues(Graph t, Graph g) {
  List<String> vs = postorder(t, t.nodes);
  vs = List.from(vs.sublist(0, vs.length - 1));
  for (var v in vs) {
    _assignCutValue(t, g, v);
  }
}

void _assignCutValue(Graph t, Graph g, String child) {
  var childLab = t.node<NodeProps>(child);
  var parent = childLab.parent;
  t.edge(child, parent)?.cutValue = _calcCutValue(t, g, child);
}

/*
 * Given the tight tree, its graph, and a child in the graph calculate and
 * return the cut value for the edge between the child and its parent.
 */
double _calcCutValue(Graph t, Graph g, String child) {
  NodeProps childLab = t.node(child);
  String? parent = childLab.parent;
  var childIsTail = true;
  EdgeProps? graphEdge = g.edge(child, parent);
  double cutValue = 0;
  if (graphEdge == null) {
    childIsTail = false;
    graphEdge = g.edge<EdgeProps>(parent!, child);
  }
  cutValue = graphEdge.weight;

  g.nodeEdges(child).forEach((e) {
    bool isOutEdge = e.v == child;
    String other = isOutEdge ? e.w : e.v;

    if (other != parent) {
      bool pointsToHead = isOutEdge == childIsTail;
      num otherWeight = g.edge2<EdgeProps>(e).weight;

      cutValue += pointsToHead ? otherWeight : -otherWeight;
      if (_isTreeEdge(t, child, other)) {
        var otherCutValue = t.edge<EdgeProps>(child, other).cutValue!;
        cutValue += pointsToHead ? -otherCutValue : otherCutValue;
      }
    }
  });

  return cutValue;
}

void _initLowLimValues(Graph tree, [String? root]) {
  root ??= tree.nodes[0];
  _dfsAssignLowLim(tree, {}, 1, root);
}

double _dfsAssignLowLim(Graph tree, Map<String, bool> visited, double nextLim, String v, [String? parent]) {
  double low = nextLim;
  NodeProps label = tree.node(v);

  visited[v] = true;
  tree.neighbors(v).forEach((w) {
    if (!visited.containsKey(w)) {
      nextLim = _dfsAssignLowLim(tree, visited, nextLim, w, v);
    }
  });

  label.low = low;
  label.lim = nextLim++;
  if (parent != null) {
    label.parent = parent;
  } else {
    label.parent = null;
  }
  return nextLim;
}

EdgeObj? leaveEdge(Graph tree) {
  return tree.edges.firstWhere((e) {
    var value = tree.edge2<EdgeProps>(e).cutValue;
    return value != null && value < 0;
  });
}

EdgeObj _enterEdge(Graph t, Graph g, EdgeObj edge) {
  var v = edge.v;
  var w = edge.w;

  if (!g.hasEdge2(v, w)) {
    v = edge.w;
    w = edge.v;
  }

  var vLabel = t.node<NodeProps>(v);
  var wLabel = t.node<NodeProps>(w);
  var tailLabel = vLabel;
  var flip = false;

  if (vLabel.lim! > wLabel.lim!) {
    tailLabel = wLabel;
    flip = true;
  }

  var candidates = g.edges.filter((edge) {
    return flip == _isDescendant(t, t.node(edge.v), tailLabel) && flip != _isDescendant(t, t.node(edge.w), tailLabel);
  });

  return candidates.reduce((acc, edge) {
    if (slack(g, edge) < slack(g, acc)) {
      return edge;
    }
    return acc;
  });
}

void _exchangeEdges(Graph t, Graph g, EdgeObj e, EdgeObj f) {
  var v = e.v;
  var w = e.w;
  t.removeEdge(v, w);
  t.setEdge(f.v, f.w, value: EdgeProps());
  _initLowLimValues(t);
  _initCutValues(t, g);
  _updateRanks(t, g);
}

void _updateRanks(Graph t, Graph g) {
  String root = t.nodes.firstWhere((v) {
    return g.node<NodeProps>(v).parent == null;
  });

  List<String> vs = preorder(t, [root]);
  vs = List.from(vs.sublist(1));
  for (var v in vs) {
    var parent = t.node<NodeProps>(v).parent;
    var edge = g.edge<EdgeProps?>(v, parent);
    var flipped = false;
    if (edge == null) {
      edge = g.edge(parent!, v);
      flipped = true;
    }
    g.node<NodeProps>(v).rank = (g.node<NodeProps>(parent!).rank! + (flipped ? edge!.minLen : -edge!.minLen)).toInt();
  }
}

bool _isTreeEdge(Graph tree, String u, String v) {
  return tree.hasEdge2(u, v);
}

bool _isDescendant(Graph tree, NodeProps vLabel, NodeProps rootLabel) {
  return rootLabel.low! <= vLabel.lim! && vLabel.lim! <= rootLabel.lim!;
}
