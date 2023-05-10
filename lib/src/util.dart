import 'dart:math' as math;

import 'package:dart_dagre/src/graph/graph.dart';
import 'package:dart_dagre/src/model/array.dart';
import 'package:dart_dagre/src/model/graph_point.dart';
import 'package:dart_dagre/src/model/graph_rect.dart';
import 'package:dart_dagre/src/model/edge_props.dart';
import 'package:dart_dagre/src/model/node_props.dart';
import 'package:dart_dagre/src/util/list_util.dart';
import 'package:dart_dagre/src/util/util.dart';
import 'package:flutter/widgets.dart';

import 'model/tmp/split.dart';
import 'model/enums/dummy.dart';

String addDummyNode(Graph g, Dummy type, NodeProps attrs, String? name) {
  String v;
  do {
    v = uniqueId(name ?? '');
  } while (g.hasNode(v));
  attrs.dummy = type;
  g.setNode(v, attrs);
  return v;
}

/*
 * Returns a new graph with only simple edges. Handles aggregation of data
 * associated with multi-edges.
 */
Graph simplify(Graph g) {
  var simplified = Graph().setGraph(g.graph);
  for (var v in g.nodes) {
    simplified.setNode(v,g.node(v));
  }
  for (var e in g.edges) {
    var simpleLabel = simplified.edgeOrNull(e.v, e.w, e.id) ?? EdgeProps(weight: 0, minLen: 1);
    var label = g.edge(e);
    EdgeProps p = EdgeProps(weight: simpleLabel.weight + label.weight, minLen: math.max(simpleLabel.minLen, label.minLen));
    simplified.setEdge(e.v, e.w, value: p);
  }
  return simplified;
}

Graph asNonCompoundGraph(Graph g) {
  var simplified = Graph(isMultiGraph: g.isMultiGraph).setGraph(g.graph);
  for (var v in g.nodes) {
    var children=g.children(v);
    if (children.isEmpty) {
      var nv=g.nodeNull(v);
      simplified.setNode(v,nv);
    }
  }
  for (var e in g.edges) {
    simplified.setEdge2(e, g.edge(e));
  }
  return simplified;
}

/*
 * Finds where a line starting at point ({x, y}) would intersect a rectangle
 * ({x, y, width, height}) if it were pointing at the rectangle's center.
 */
GraphPoint intersectRect(GraphRect rect, GraphPoint point) {
  var x = rect.x;
  var y = rect.y;

  // Rectangle intersection algorithm from:
  // http://math.stackexchange.com/questions/108113/find-edge-between-two-boxes
  var dx = point.x - x;
  var dy = point.y - y;
  var w = rect.width / 2;
  var h = rect.height / 2;

  if (dx==0 && dy==0) {
    throw FlutterError("Not possible to find intersection inside of the rectangle");
  }

  num sx, sy;
  if (dy.abs() * w > dx.abs() * h) {
    if (dy < 0) {
      h = -h;
    }
    sx = h * dx / dy;
    sy = h;
  } else {
    if (dx < 0) {
      w = -w;
    }
    sx = w;
    sy = w * dy / dx;
  }
  return GraphPoint(x + sx, y + sy);
}

/*
 * Given a DAG with each node assigned "rank" and "order" properties, this
 * function will produce a matrix with the ids of each node.
 */
List<List<String>> buildLayerMatrix(Graph g) {
  List<Array<String>> layering = [];
  int v =maxRank(g)! +1;
  for (int i = 0; i < v; i++) {
    layering.add(Array());
  }
  for (var v in g.nodes) {
    var node = g.node(v);
    int? rank = node.rankNull;
    if (rank != null) {
      layering[rank][node.order] = v;
    }
  }
  List<List<String>> rl = [];
  for (var element in layering) {
    rl.add(element.toList());
  }
  return rl;
}

/*
 * Adjusts the ranks for all nodes in the graph such that all nodes v have
 * rank(v) >= 0 and at least one node w has rank(w) = 0.
 */
void normalizeRanks(Graph g) {
  var minv = (min(g.nodes.map((v)=> g.node(v).rank)))!.toInt();
  for (var v in g.nodes) {
    var node = g.node(v);
    if (node.rankNull != null) {
      node.rank -= minv;
    }
  }
}

void removeEmptyRanks(Graph g) {
  // Ranks may not start at 0, so we need to offset them
  List<int> rankList = g.nodes.map2((p0, p1) => g.node(p0).rankNull);
  var offset = min(rankList) ?? 0;
  Array<List<String>> layers = Array();
  for (var v in g.nodes) {
    var rank = (g.node(v).rank - offset).toInt();
    if (!layers.has(rank)) {
      layers[rank] = [];
    }
    layers[rank]!.add(v);
  }

  var delta = 0;
  var nodeRankFactor = g.graph.nodeRankFactor;

  layers.forEach((vs, i) {
    if ((vs == null||vs.isEmpty) && i % nodeRankFactor != 0) {
      --delta;
    } else if (delta != 0) {
      for (var v in vs!) {
        g.node(v).rank +=delta;
      }
    }
  });
}

String addBorderNode(Graph g, [String? prefix, int? rank, int? order]) {
  NodeProps np = NodeProps(width: 0,height: 0);
  if (rank != null && order != null) {
    np.rank = rank;
    np.order = order;
  }
  return addDummyNode(g, Dummy.border, np, prefix);
}

int? maxRank(Graph g) {
  return max(g.nodes.map2((v, i) {
    return g.node(v).rankNull;
  }))?.toInt();
}

/*
 * Partition a collection into two groups: `lhs` and `rhs`. If the supplied
 * function returns true for an entry it goes into `lhs`. Otherwise it goes
 * into `rhs.
 */
Split<T> partition<T>(List<T> collection, bool Function(T) fn) {
  Split<T> split = Split();
  for (var value in collection) {
    if (fn(value)) {
      split.lhs.add(value);
    } else {
      split.rhs.add(value);
    }
  }

  return split;
}
