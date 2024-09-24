import 'dart:math';

import 'package:dart_dagre/src/graph/graph.dart';
import 'package:dart_dagre/src/model/enums/rank_dir.dart';
import 'package:dart_dagre/src/model/edge_props.dart';
import 'package:dart_dagre/src/model/node_props.dart';

import 'model/graph_props.dart';

void adjust(Graph g) {
  var rankDir = g.getLabel<GraphProps>().rankDir;
  if (rankDir ==RankDir.ltr || rankDir ==RankDir.rtl) {
    _swapWidthHeight(g);
  }
}

void undo(Graph g) {
  var rankDir = g.getLabel<GraphProps>().rankDir;
  if (rankDir == RankDir.btt || rankDir ==RankDir.rtl) {
    _reverseY(g);
  }

  if (rankDir ==RankDir.ltr || rankDir ==RankDir.rtl) {
    _swapXY(g);
    _swapWidthHeight(g);
  }
}

void _swapWidthHeight(Graph g) {
  for (var v in g.nodesIterable) {
    _swapWidthHeightOne(g.node(v));
  }
  for (var e in g.edgesIterable) {
    _swapWidthHeightOne2(g.edge2<EdgeProps>(e));
  }
}

void _swapWidthHeightOne(NodeProps attrs) {
  var w = attrs.width;
  attrs.width = attrs.height;
  attrs.height = w;
}
void _swapWidthHeightOne2(EdgeProps attrs) {
  var w = attrs.width;
  attrs.width = attrs.height;
  attrs.height = w;
}

void _reverseY(Graph g) {
  for (var v in g.nodesIterable) {
    NodeProps np=g.node(v);
    np.y = -np.y!;
  }
  for (var e in g.edgesIterable) {
    var edge = g.edge2<EdgeProps>(e);
    for (var p in edge.points) {
      p.y=-p.y;
    }
    if (edge.y != null) {
      edge.y = -edge.y!;
    }
  }
}

void _swapXY(Graph g) {
  for (var v in g.nodesIterable) {
    _swapXYOne(g.node<NodeProps>(v));
  }

  for (var e in g.edgesIterable) {
    var edge = g.edge2<EdgeProps>(e);
    edge.points=List.from(edge.points.map((e) => Point(e.y, e.x)));

    if(edge.x!=null){
      var x = edge.x!;
      edge.x = edge.y;
      edge.y = x;
    }
  }
}

void _swapXYOne(NodeProps attrs) {
  var x = attrs.x;
  attrs.x = attrs.y;
  attrs.y = x;
}
