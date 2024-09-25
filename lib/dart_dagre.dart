library dagre;

import 'dart:convert';
import 'dart:ui';

import 'src/layout.dart' as layer;
import 'src/graph/graph.dart';
import 'src/model/edge_props.dart';
import 'src/model/enums/acyclicer.dart';
import 'src/model/enums/align.dart';
import 'src/model/enums/label_pos.dart';
import 'src/model/enums/rank_dir.dart';
import 'src/model/enums/ranker.dart';
import 'src/model/graph_props.dart';
import 'src/model/node_props.dart';

export 'src/model/enums/acyclicer.dart';
export 'src/model/enums/align.dart';
export 'src/model/enums/label_pos.dart';
export 'src/model/enums/rank_dir.dart';
export 'src/model/enums/ranker.dart';

///给定节点和边进行图布局
///[multiGraph] 是否为多边图(同一对节点之间可以有多个边的图)
///[compoundGraph] 是否为复合图(一个节点可以是其它节点的父节点)
///[directedGraph] 是否为有向图(如果是，那么边上节点的顺序是有效的)
DagreResult layout(
  List<DagreNode> nodeList,
  List<DagreEdge> edgeList,
  GraphConfig config, {
  bool multiGraph = false,
  bool compoundGraph = true,
  bool directedGraph = true,
  NodeProps Function(String)? nodeLabelFun,
  EdgeProps Function(String, String, String?)? edgeLabelFun,
}) {
  Graph graph = Graph(isCompound: compoundGraph, isMultiGraph: multiGraph, isDirected: directedGraph);
  if (nodeLabelFun != null) {
    graph.setDefaultNodePropsFun(nodeLabelFun);
  }
  if (edgeLabelFun != null) {
    graph.setDefaultEdgePropsFun(edgeLabelFun);
  }

  for (var ele in nodeList) {
    graph.setNode(ele.id, NodeProps(width: ele.width, height: ele.height));
  }

  for (var edge in edgeList) {
    String v = edge.source.id;
    String w = edge.target.id;
    EdgeProps props = EdgeProps(
      minLen: edge.minLen,
      weight: edge.weight,
      width: edge.width,
      height: edge.height,
      labelOffset: edge.labelOffset,
      labelPos: edge.labelPos,
    );
    graph.setEdge(v, w, value: props, id: edge.id);
  }

  GraphProps props = GraphProps();
  props.rankDir = config.rankDir;
  props.align = config.align;
  props.acyclicer = config.acyclicer;
  props.ranker = config.ranker;
  props.marginX = config.marginX;
  props.marginY = config.marginY;
  props.rankSep = config.rankSep;
  props.edgeSep = config.edgeSep;
  props.nodeSep = config.nodeSep;
  graph.setLabel(props);

  layer.layout(graph,config);

  DagreResult result = DagreResult(
    graph.getLabel<GraphProps>().width ?? 0,
    graph.getLabel<GraphProps>().height ?? 0,
  );
  for (var v in graph.nodes) {
    var node = graph.node(v);
    result.nodePosMap[v] = Rect.fromCenter(
      center: Offset(node.x.toDouble(), node.y.toDouble()),
      width: node.width.toDouble(),
      height: node.height.toDouble(),
    );
  }

  for (var v in graph.edges) {
    var e = graph.edge2<EdgeProps>(v);
    EdgeResult result = EdgeResult(e.x!.toDouble(), e.y!.toDouble());
    for (var ep in e.points) {
      result.points.add(Offset(ep.x.toDouble(), ep.y.toDouble()));
    }
  }
  return result;
}

class DagreNode {
  final String id;
  final double width;
  final double height;

  DagreNode(
    this.id, {
    this.width = 0,
    this.height = 0,
  });

  @override
  int get hashCode {
    return id.hashCode;
  }

  @override
  bool operator ==(Object other) {
    return other is DagreNode && other.id == id;
  }
}

class DagreEdge {
  final String? id;
  final DagreNode source;
  final DagreNode target;
  final double minLen;
  final double weight;
  final double labelOffset;
  final LabelPosition labelPos;
  final double width;
  final double height;

  DagreEdge(
    this.source,
    this.target, {
    this.minLen = 1,
    this.weight = 1,
    this.labelOffset = 10,
    this.labelPos = LabelPosition.right,
    this.width = 0,
    this.height = 0,
    this.id,
  });
}

class GraphConfig {
  final RankDir rankDir;
  final GraphAlign? align;

  ///节点水平之间的间距
  final double marginX;

  ///节点竖直之间的间距
  final double marginY;

  /// 不同rank层之间的间距
  final double rankSep;

  ///边之间的水平间距
  final double edgeSep;

  ///节点之间水平间距
  final double nodeSep;

  ///控制查找图形时使用的方法
  final Acyclicer acyclicer;

  ///控制为图中每个节点分配层级的算法类型
  final Ranker ranker;

  final void Function(Graph g)? customOrder;

  final bool disableOptimalOrderHeuristic;

  GraphConfig({
    this.rankDir = RankDir.ttb,
    this.align,
    this.marginX = 0,
    this.marginY = 0,
    this.rankSep = 50,
    this.edgeSep = 10,
    this.nodeSep = 10,
    this.acyclicer = Acyclicer.none,
    this.ranker = Ranker.networkSimplex,
    this.disableOptimalOrderHeuristic=false,
    this.customOrder,
  });
}

class DagreResult {
  final double graphWidth;
  final double graphHeight;
  final Map<String, Rect> nodePosMap = {};
  final Map<String, EdgeResult> edgePosMap = {};

  DagreResult(this.graphWidth, this.graphHeight);

  @override
  String toString() {
    Map<String, dynamic> map = {};
    map["width"] = graphWidth;
    map["height"] = graphHeight;
    Map<String, String> rm = nodePosMap.map((k, v) => MapEntry(k, v.toString()));
    map["nodes"] = rm;
    map["edges"] = edgePosMap.map((k, v) => MapEntry(k, v.toString()));
    return jsonEncode(map);
  }
}

class EdgeResult {
  final double x;
  final double y;
  final List<Offset> points = [];

  EdgeResult(this.x, this.y);

  @override
  String toString() {
    return "x:$x y:$y points:${points.toString()}";
  }
}
