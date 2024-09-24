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

import 'model/graph_props.dart';
import 'model/tmp/split.dart' as sp;
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

Graph simplify(Graph g) {
  var simplified = Graph().setLabel(g.getLabel());
  for (var v in g.nodes) {
    simplified.setNode(v,g.node(v));
  }

  for (var e in g.edges) {
    var simpleLabel = simplified.edge<EdgeProps?>(e.v, e.w) ?? EdgeProps(weight: 0, minLen: 1);
    var label = g.edge2<EdgeProps>(e);
    EdgeProps p = EdgeProps(
        weight: simpleLabel.weight + label.weight,
        minLen: math.max(
          simpleLabel.minLen,
          label.minLen,
        ));
    simplified.setEdge(e.v, e.w, value: p);
  }
  return simplified;
}

Graph asNonCompoundGraph(Graph g) {
  var simplified = Graph(isMultiGraph: g.isMultiGraph).setLabel(g.getLabel());
  for (var v in g.nodes) {
    var children=g.children(v);
    if (children.isEmpty) {
      simplified.setNode(v, g.node(v));
    }
  }
  for (var e in g.edges) {
    simplified.setEdge2(e, g.edge2(e));
  }
  return simplified;
}

Map<String, Map<String, double>> successorWeights(Graph g) {
  var weightMap = g.nodes.map((v) {
    Map<String, double> sucs = {};
    g.outEdges(v).forEach((e) {
      var v = sucs[e.w] ?? 0;
      sucs[e.w] = v + g
          .edge2<EdgeProps>(e)
          .weight;
    });
    return sucs;
  }).toList();
  return zipObject(g.nodes, weightMap);
}

Map<String, Map<String, double>> predecessorWeights(Graph g) {
  var weightMap = g.nodes.map((v) {
    Map<String, double> preds = {};
    g.inEdges(v).forEach((e) {
      var v = preds[e.v] ?? 0;
      preds[e.v] = v + g
          .edge2<EdgeProps>(e)
          .weight;
    });
    return preds;
  }).toList();
  return zipObject(g.nodes, weightMap);
}

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

  double sx, sy;
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

List<List<String>> buildLayerMatrix(Graph g) {
  List<Array<String>> layering = [];
  int v =maxRank(g)! +1;
  for (int i = 0; i < v; i++) {
    layering.add(Array());
  }
  for (var v in g.nodes) {
    var node = g.node<NodeProps>(v);
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

void normalizeRanks(Graph g) {
  var nodeRanks = g.nodes.map((v) {
    var rank = g
        .node<NodeProps>(v)
        .rankNull;
    if (rank == null) {
      return (double.maxFinite - 2).toInt();
    }
    return rank;
  }).toList();

  var min=(double.maxFinite-20).toInt();
  for(var item in nodeRanks){
    if(item<min){
      min=item;
    }
  }
  for (var v in g.nodes) {
    var node = g.node<NodeProps>(v);
    if (node.rankNull != null) {
      node.rank -= min;
    }
  }
}

void removeEmptyRanks(Graph g) {
  List<int> rankList = g.nodes.map2((p0, p1) => g.node<NodeProps>(p0).rank);
  int offset = (min(rankList) ?? 0).toInt();
  Array<List<String>> layers = Array();
  for (var v in g.nodes) {
    var rank = g.node<NodeProps>(v).rank - offset;
    if (!layers.has(rank)) {
      layers[rank] = [];
    }
    layers[rank]!.add(v);
  }

  var delta = 0;
  var nodeRankFactor = g.getLabel<GraphProps>().nodeRankFactor;

  layers.forEach((vs, i) {
    if ((vs == null||vs.isEmpty) && i % nodeRankFactor != 0) {
      --delta;
    } else if ((vs!=null&&vs.isNotEmpty)&&delta != 0) {
      for (var v in vs) {
        g.node<NodeProps>(v).rank +=delta;
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
    var r= g.node<NodeProps>(v).rankNull;
    r ??= (double.maxFinite-20).toInt();
    return r;
  }))?.toInt();
}

sp.Split<T> partition<T>(List<T> collection, bool Function(T) fn) {
  sp.Split<T> split = sp.Split();
  for (var value in collection) {
    if (fn(value)) {
      split.lhs.add(value);
    } else {
      split.rhs.add(value);
    }
  }
  return split;
}

Map<String, Map<String, double>> zipObject(List<String> props, List<Map<String, double>> values) {
  Map<String, Map<String, double>> result = {};
  int i = 0;
  for (var item in props) {
    result[item] = values[i];
    i++;
  }
  return result;
}

dynamic applyWithChunking<T>(dynamic Function(List<dynamic>) fn, List<T> argsArray) {
  if (argsArray.length > CHUNKING_THRESHOLD) {
    var chunks = splitToChunks(argsArray);
    return fn.call(chunks.map((chunk) => fn.call(chunk)).toList());
  } else {
    return fn.call(argsArray);
  }
}

const int CHUNKING_THRESHOLD = 65535;

List<List<T>> splitToChunks<T>(List<T> array, [int chunkSize = CHUNKING_THRESHOLD]) {
  List<List<T>> chunks = [];
  for (var i = 0; i < array.length; i += chunkSize) {
    var end = i + chunkSize;
    if (end > array.length) {
      end = array.length;
    }
    chunks.add(array.sublist(i, end));
  }
  return chunks;
}