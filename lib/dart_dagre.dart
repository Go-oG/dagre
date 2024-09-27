library dagre;

import 'dart:convert';
import 'dart:ui';
import 'package:dart_dagre/src/model/graph_label.dart';
import 'package:dart_dagre/src/model/graph_point.dart';
import 'package:dart_dagre/src/model/props.dart';
import 'src/layout.dart' as layer;
import 'src/graph/graph.dart';
import 'src/model/enums/acyclicer.dart';
import 'src/model/enums/align.dart';
import 'src/model/enums/label_pos.dart';
import 'src/model/enums/rank_dir.dart';
import 'src/model/enums/ranker.dart';
export 'src/model/enums/acyclicer.dart';
export 'src/model/enums/align.dart';
export 'src/model/enums/label_pos.dart';
export 'src/model/enums/rank_dir.dart';
export 'src/model/enums/ranker.dart';

///给定节点和边进行图布局
///[multiGraph] 是否为多边图(同一对节点之间可以有多个边的图)
///[compoundGraph] 是否为复合图(一个节点可以是其它节点的父节点)
///[directedGraph] 是否为有向图(如果是，那么边上节点的顺序是有效的)
DagreResult layout(DagreGraph inputGraph,
    DagreConfig config, {
      Props Function(String)? nodeLabelFun,
      Props Function(String, String, String?)? edgeLabelFun,
}) {
  Graph layoutGraph = Graph(isCompound: true, isMultiGraph: true);
  nodeLabelFun = nodeLabelFun ?? (String id) => Props();
  layoutGraph.setDefaultNodePropsFun(nodeLabelFun);
  edgeLabelFun = edgeLabelFun ?? (v, w, id) => Props();
  layoutGraph.setDefaultEdgeLabelFun(edgeLabelFun);
  for (var ele in inputGraph.nodeMap.values) {
    layoutGraph.setNode(ele.id, {widthK: ele.width, heightK: ele.height}.toProps);
  }
  for (var edge in inputGraph.edgeMap.values) {
    var props = {
      minLenK: edge.minLen,
      weightK: edge.weight,
      widthK: edge.width,
      heightK: edge.height,
      labelOffsetK: edge.labelOffset,
      labelPosK: edge.labelPos,
    };
    layoutGraph.setEdge2(edge.source, edge.target, value: props.toProps, name: edge.id);
  }

  GraphLabel label = GraphLabel();
  label.rankDir = config.rankDir;
  label.align = config.align;
  label.acyclicer = config.acyclicer;
  label.ranker = config.ranker;
  label.marginX = config.marginX;
  label.marginY = config.marginY;
  label.rankSep = config.rankSep;
  label.edgeSep = config.edgeSep;
  label.nodeSep = config.nodeSep;
  layoutGraph.label = label;
  layer.layout(layoutGraph, config);
  for (var v in layoutGraph.nodes) {
    var node = layoutGraph.node(v);
    var rect = Rect.fromCenter(
      center: Offset(node.getD(xK), node.getD(yK)),
      width: node.getD(widthK),
      height: node.getD(heightK),
    );
    inputGraph.nodeMap[v]!.position = rect;
  }
  for (var v in layoutGraph.edges) {
    var edge = layoutGraph.edge2(v);
    var resultEdge = inputGraph.findEdgeById(v.id!)!;
    List<Offset> points = [];
    for (var ep in edge.get(pointsK) as List<GraphPoint>) {
      points.add(Offset(ep.x, ep.y));
    }
    resultEdge.points = points;
  }
  return DagreResult(layoutGraph.label.width!, layoutGraph.label.height!, inputGraph);
}

class DagreGraph {
  final Map<String, DagreNode> _nodeMap = {};

  final Map<String, DagreEdge> _edgeMap = {};

  Map<String, DagreNode> get nodeMap => _nodeMap;

  Map<String, DagreEdge> get edgeMap => _edgeMap;

  List<DagreNode> get nodes => List.from(_nodeMap.values);

  List<DagreEdge> get edges => List.from(_edgeMap.values);

  void addNode(DagreNode node) {
    _nodeMap[node.id] = node;
  }

  void addNode2(String id, [double width = 0, double height = 0]) {
    _nodeMap[id] = DagreNode(id, width: width, height: height);
  }

  void removeNode(String id) {
    _nodeMap.remove(id);
    removeEdge(id);
  }

  void addEdge(DagreEdge edge) {
    if (_nodeMap[edge.source] == null) {
      throw UnsupportedError("please add source Node");
    }
    if (_nodeMap[edge.target] == null) {
      throw UnsupportedError("please add target Node");
    }
    _edgeMap[edge.id] = edge;
  }

  void removeEdge(String source, [String? target]) {
    Set<DagreEdge> set = <DagreEdge>{};
    for (var item in _edgeMap.values) {
      if (item.source == source) {
        if (target == null || item.target == target) {
          set.add(item);
        }
      }
    }
    _edgeMap.removeWhere((k, v) => set.contains(v));
  }

  DagreEdge? findEdge(String source, String target) {
    for (var item in _edgeMap.values) {
      if (item.source == source && item.target == target) {
        return item;
      }
    }
    return null;
  }

  DagreEdge? findEdgeById(String edgeId) {
    return _edgeMap[edgeId];
  }

  Map<String, dynamic> get toMap {
    Map<String, dynamic> map = {};
    List<dynamic> nodeList = [];
    List<dynamic> edgeList = [];
    for (var node in nodeMap.values) {
      nodeList.add(node.toMap);
    }
    for (var edge in edgeMap.values) {
      edgeList.add(edge.toMap);
    }

    map["nodes"] = nodeList;
    map['edges'] = edgeList;
    return map;
  }

  @override
  String toString() {
    return jsonEncode(toMap);
  }
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

  Rect? position;

  Map<String, dynamic> get toMap {
    Map<String, dynamic> map = {};
    map["id"] = id;
    map['width'] = width.toStringAsFixed(2);
    map['height'] = height.toStringAsFixed(2);
    var pp = position;
    if (pp == null) {
      map["position"] = '';
    } else {
      map["position"] =
          "LTRB:${pp.left.toStringAsFixed(2)},${pp.top.toStringAsFixed(2)},${pp.right.toStringAsFixed(2)},${pp.bottom.toStringAsFixed(2)}";
    }
    return map;
  }
}

class DagreEdge {
  late final String id;
  final String source;
  final String target;
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
    String? id,
  }) {
    if (id == null || id.isEmpty) {
      this.id = '$source->$target';
    } else {
      this.id = id;
    }
  }

  @override
  int get hashCode {
    return id.hashCode;
  }

  @override
  bool operator ==(Object other) {
    return other is DagreEdge && other.id == id;
  }

  List<Offset> points = [];

  Map<String, dynamic> get toMap {
    Map<String, dynamic> map = {};
    map["id"] = id;
    map["source"] = source;
    map["target"] = target;
    map["minLen"] = minLen.toStringAsFixed(2);
    map["weight"] = weight.toStringAsFixed(2);
    map["labelOffset"] = labelOffset.toStringAsFixed(2);
    map["labelPos"] = labelPos.toString();
    map["width"] = width.toStringAsFixed(2);
    map["height"] = height.toStringAsFixed(2);
    map['points'] = points.map((e) => "[${e.dx.toStringAsFixed(2)},${e.dy.toStringAsFixed(2)}]").toList();
    return map;
  }
}

class DagreConfig {
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

  DagreConfig({
    this.rankDir = RankDir.ttb,
    this.align,
    this.marginX = 0,
    this.marginY = 0,
    this.rankSep = 50,
    this.edgeSep = 20,
    this.nodeSep = 50,
    this.acyclicer = Acyclicer.none,
    this.ranker = Ranker.networkSimplex,
    this.disableOptimalOrderHeuristic=false,
    this.customOrder,
  });
}

class DagreResult {
  final double graphWidth;
  final double graphHeight;
  final DagreGraph graph;

  DagreResult(this.graphWidth, this.graphHeight, this.graph);

  @override
  String toString() {
    Map<String, dynamic> map = {};
    map["width"] = graphWidth.toStringAsFixed(2);
    map["height"] = graphHeight.toStringAsFixed(2);
    map["graph"] = graph.toMap;
    return jsonEncode(map);
  }
}
