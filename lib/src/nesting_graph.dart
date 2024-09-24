import 'package:dart_dagre/src/graph/graph.dart';
import 'package:dart_dagre/src/model/enums/dummy.dart';
import 'package:dart_dagre/src/model/edge_props.dart';
import 'package:dart_dagre/src/model/node_props.dart';
import 'package:dart_dagre/src/util.dart' as util;
import 'package:dart_dagre/src/util/list_util.dart';

import 'model/graph_props.dart';

void run(Graph g) {
  var root = util.addDummyNode(g, Dummy.root, NodeProps(), "_root");
  Map<String, int> depths = _treeDepths(g);
  double height = max(depths.values)! - 1;
  double nodeSep = 2 * height + 1;
  g.getLabel<GraphProps>().nestingRoot = root;

  for (var e in g.edgesIterable) {
    EdgeProps p = g.edge2(e);
    p.minLen *= nodeSep;
  }

  double weight = _sumWeights(g) + 1;

  g.children().forEach((child) {
    _dfs(g, root, nodeSep, weight, height, depths, child);
  });

  g.getLabel<GraphProps>().nodeRankFactor = nodeSep;
}

void _dfs(Graph g, String root, double nodeSep, double weight, double height, Map<String, int> depths, String v) {
  var children = g.children(v);
  if (children.isEmpty) {
    if (v != root) {
      g.setEdge(root, v, value: EdgeProps(weight: 0, minLen: nodeSep));
    }
    return;
  }

  var top = util.addBorderNode(g, "_bt");
  var bottom = util.addBorderNode(g, "_bb");
  var label = g.node(v);

  g.setParent(top, v);
  label.borderTop = top;
  g.setParent(bottom, v);
  label.borderBottom = bottom;

  for (var child in children) {
    _dfs(g, root, nodeSep, weight, height, depths, child);
    var childNode = g.node<NodeProps>(child);
    var childTop = childNode.borderTop ?? child;
    var childBottom = childNode.borderBottom ?? child;
    var thisWeight = childNode.borderTop != null ? weight : 2 * weight;
    double minlen = childTop != childBottom ? 1 : (height - depths[v]! + 1);
    g.setEdge(
      top,
      childTop,
      value: EdgeProps(weight: thisWeight, minLen: minlen, nestingEdge: true),
    );
    g.setEdge(
      childBottom,
      bottom,
      value: EdgeProps(weight: thisWeight, minLen: minlen, nestingEdge: true),
    );
  }

  if (g.parent(v) == null) {
    g.setEdge(root, top, value: EdgeProps(weight: 0, minLen: height + depths[v]!));
  }
}

Map<String, int> _treeDepths(Graph g) {
  Map<String, int> depths = {};
  dfs(v, depth) {
    var children = g.children(v);
    if (children.isNotEmpty) {
      for (var child in children) {
        dfs(child, depth + 1);
      }
    }
    depths[v] = depth;
  }

  g.children().forEach((v) {
    dfs(v, 1);
  });
  return depths;
}

num _sumWeights(Graph g) {
  return g.edges.reduce2<num>((acc, e) {
    return e + (g.edge2<EdgeProps>(acc).weight);
  }, 0);
}

void cleanup(Graph g) {
  var graphLabel = g.getLabel<GraphProps>();
  g.removeNode(graphLabel.nestingRoot);
  graphLabel.nestingRoot = null;

  for (var e in g.edges) {
    var edge = g.edge2<EdgeProps>(e);
    if (edge.nestingEdge==true) {
      g.removeEdge2(e);
    }
  }
}
