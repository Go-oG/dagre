import 'dart:math' as math;
import 'package:dart_dagre/dart_dagre.dart';
import 'package:dart_dagre/src/graph/graph.dart';
import 'package:dart_dagre/src/model/enums/dummy.dart';
import 'package:dart_dagre/src/model/graph_rect.dart';
import 'package:dart_dagre/src/model/enums/label_pos.dart';
import 'package:dart_dagre/src/model/enums/rank_dir.dart';
import 'package:dart_dagre/src/model/tmp/self_edge_data.dart';
import 'package:dart_dagre/src/parent_dummy_chains.dart';
import 'package:dart_dagre/src/position/index.dart';
import 'package:dart_dagre/src/model/edge_props.dart';
import 'package:dart_dagre/src/model/graph_props.dart';
import 'package:dart_dagre/src/model/node_props.dart';
import 'package:dart_dagre/src/util.dart';
import 'package:dart_dagre/src/util.dart' as util;
import 'package:dart_dagre/src/util/list_util.dart';
import 'package:dart_dagre/src/acyclic.dart' as acyclic;
import 'package:dart_dagre/src/nesting_graph.dart' as nesting_graph;
import 'package:dart_dagre/src/rank/index.dart';
import 'package:dart_dagre/src/normalize.dart' as normalize;
import 'package:dart_dagre/src/coordinate_system.dart' as coordinate_system;

import 'add_border_segments.dart';
import 'model/graph_point.dart';
import 'order/index.dart';

void layout(Graph g,GraphConfig config) {
  var layoutGraph = _buildLayoutGraph(g);
  _runLayout(layoutGraph,config);
  _updateInputGraph(g, layoutGraph);
}

void _runLayout(Graph g,GraphConfig config) {
  _makeSpaceForEdgeLabels(g);
  _removeSelfEdges(g);
  acyclic.run(g);
  nesting_graph.run(g);
  rank(util.asNonCompoundGraph(g));
  _injectEdgeLabelProxies(g);
  removeEmptyRanks(g);
  nesting_graph.cleanup(g);
  normalizeRanks(g);
  _assignRankMinMax(g);
  _removeEdgeLabelProxies(g);
  normalize.run(g);
  parentDummyChains(g);
  addBorderSegments(g);
  order(g,config);
  _insertSelfEdges(g);
  coordinate_system.adjust(g);
  position(g);
  _positionSelfEdges(g);
  _removeBorderNodes(g);
  normalize.undo(g);
  _fixupEdgeLabelCoords(g);
  coordinate_system.undo(g);
  _translateGraph(g);
  _assignNodeIntersects(g);
  _reversePointsForReversedEdges(g);
  acyclic.undo(g);
}

void _updateInputGraph(Graph inputGraph, Graph layoutGraph) {
  for (var v in inputGraph.nodes) {
    var inputLabel = inputGraph.node<NodeProps?>(v);
    var layoutLabel = layoutGraph.node<NodeProps>(v);

    if (inputLabel != null) {
      inputLabel.x = layoutLabel.x;
      inputLabel.y = layoutLabel.y;
      inputLabel.rank = layoutLabel.rank;

      if (layoutGraph.children(v).isNotEmpty) {
        inputLabel.width = layoutLabel.width;
        inputLabel.height = layoutLabel.height;
      }
    }
  }

  for (var e in inputGraph.edges) {
    var inputLabel = inputGraph.edge2<EdgeProps>(e);
    var layoutLabel = layoutGraph.edge2<EdgeProps>(e);

    inputLabel.points = layoutLabel.points;
    if (layoutLabel.x != null) {
      inputLabel.x = layoutLabel.x;
      inputLabel.y = layoutLabel.y;
    }
  }

  inputGraph.getLabel<GraphProps>().width = layoutGraph.getLabel<GraphProps>().width;
  inputGraph.getLabel<GraphProps>().height = layoutGraph.getLabel<GraphProps>().height;
}

Graph _buildLayoutGraph(Graph inputGraph) {
  var g = Graph(isMultiGraph: true, isCompound: true);
  var graph = inputGraph.getLabel<GraphProps>();
  GraphProps gp = GraphProps(rankSep: 50, edgeSep: 20, nodeSep: 50, rankDir: RankDir.ttb);

  gp.nodeSep = graph.nodeSep;
  gp.edgeSep = graph.edgeSep;
  gp.rankSep = graph.rankSep;
  gp.marginX = graph.marginX;
  gp.marginY = graph.marginY;
  gp.acyclicer = graph.acyclicer;
  gp.ranker = graph.ranker;
  gp.rankDir = graph.rankDir;
  gp.align = graph.align;
  g.setLabel(gp);

  for (var v in inputGraph.nodes) {
    var node = inputGraph.node<NodeProps?>(v) ?? NodeProps();
    var np = NodeProps();
    np.width = node.width;
    np.height = node.height;
    if (np.width < 0) {
      np.width = 0;
    }
    if (np.height < 0) {
      np.height = 0;
    }

    g.setNode(v, np);
    g.setParent(v, inputGraph.parent(v));
  }

  for (var e in inputGraph.edges) {
    EdgeProps? edge = inputGraph.edge<EdgeProps?>(e.v, e.w, e.id);

    EdgeProps ep = EdgeProps(
      minLen: 1,
      width: 0,
      height: 0,
      weight: 1,
      labelOffset: 10,
      labelPos: LabelPosition.right,
    );
    if (edge != null) {
      ep.minLen = edge.minLen;
      ep.weight = edge.weight;
      ep.width = edge.width;
      ep.height = edge.height;
      ep.labelOffset = edge.labelOffset;
      ep.labelPos = edge.labelPos;
    }
    g.setEdge2(e, ep);
  }
  return g;
}

void _makeSpaceForEdgeLabels(Graph g) {
  var graph = g.getLabel<GraphProps>();
  graph.rankSep /= 2;
  g.edges.each((e, p1) {
    var edge = g.edge2<EdgeProps>(e);
    edge.minLen *= 2;
    if (edge.labelPos != LabelPosition.center) {
      if (graph.rankDir == RankDir.ttb || graph.rankDir == RankDir.btt) {
        edge.width += edge.labelOffset;
      } else {
        edge.height += edge.labelOffset;
      }
    }
  });
}

void _injectEdgeLabelProxies(Graph g) {
  for (var e in g.edgesIterable) {
    var edge = g.edge2<EdgeProps>(e);
    if (edge.width >= 0 && edge.height >= 0) {
      var v = g.node<NodeProps>(e.v);
      var w = g.node<NodeProps>(e.w);
      var label = NodeProps(rank: ((w.rank! - v.rank!) / 2 + v.rank!).toInt(), e: e);
      util.addDummyNode(g, Dummy.edgeProxy, label, "_ep");
    }
  }
}

void _assignRankMinMax(Graph g) {
  int maxRank = 0;
  for (var v in g.nodesIterable) {
    var node = g.node<NodeProps>(v);
    var value = node.borderTop;
    if (value != null) {
      node.minRank = g.node<NodeProps>(value).rank;
      node.maxRank = g.node<NodeProps>(node.borderBottom!).rank;
      maxRank = math.max(maxRank, node.maxRank!);
    }
  }
  g.getLabel<GraphProps>().maxRank = maxRank;
}

void _removeEdgeLabelProxies(Graph g) {
  for (var v in g.nodes) {
    var node = g.node<NodeProps>(v);
    if (node.dummy == Dummy.edgeProxy) {
      g.edge2<EdgeProps>(node.e!).labelRank = node.rank;
      g.removeNode(v);
    }
  }
}

void _translateGraph(Graph g) {
  var minX = double.maxFinite;
  var maxX = 0;
  var minY = double.maxFinite;
  var maxY = 0;
  var graphLabel = g.getLabel<GraphProps>();
  var marginX =graphLabel.marginX;
  var marginY =graphLabel.marginY;

  ///attrs is NodeProps or EdgeProps
  getExtremes(attrs) {
    if (attrs is NodeProps) {
      double x = attrs.x!;
      double y = attrs.y!;
      double w = attrs.width;
      double h = attrs.height;
      minX = math.min(minX, x - w / 2);
      maxX = math.max(maxX, (x + w / 2)).toInt();
      minY = math.min(minY, y - h / 2);
      maxY = math.max(maxY, (y + h / 2)).toInt();
    } else if (attrs is EdgeProps) {
      double x = attrs.x!;
      double y = attrs.y!;
      num w = attrs.width;
      num h = attrs.height;
      minX = math.min(minX, x - w / 2);
      maxX = math.max(maxX, (x + w / 2)).toInt();
      minY = math.min(minY, y - h / 2);
      maxY = math.max(maxY, (y + h / 2)).toInt();
    }
  }

  for (var v in g.nodesIterable) {
    getExtremes(g.node(v));
  }

  for (var e in g.edgesIterable) {
    var edge = g.edge2<EdgeProps>(e);
    if (edge.x != null) {
      getExtremes(edge);
    }
  }

  minX -= marginX;
  minY -= marginY;

  for (var v in g.nodesIterable) {
    var node = g.node<NodeProps>(v);
    node.x = node.x! - minX;
    node.y = node.y! - minY;
  }

  for (var e in g.edgesIterable) {
    var edge = g.edge2<EdgeProps>(e);
    edge.points.each((p, p1) {
      p.x -= minX;
      p.y -= minY;
    });
    if (edge.x != null) {
      edge.x = edge.x! - minX;
    }
    if (edge.y != null) {
      edge.y = edge.y! - minY;
    }
  }
  graphLabel.width = maxX - minX + marginX;
  graphLabel.height = maxY - minY + marginY;
}

void _assignNodeIntersects(Graph g) {
  for (var e in g.edgesIterable) {
    var edge = g.edge2<EdgeProps>(e);
    var nodeV = g.node<NodeProps>(e.v);
    var nodeW = g.node<NodeProps>(e.w);
    GraphPoint p1, p2;
    if (edge.points.isEmpty) {
      p1 = GraphPoint(nodeW.x!.toDouble(), nodeW.y!.toDouble());
      p2 = GraphPoint(nodeV.x!.toDouble(), nodeV.y!.toDouble());
    } else {
      p1 = edge.points[0];
      p2 = edge.points.last;
    }

    edge.points.insert(0, util.intersectRect(GraphRect(nodeV.x!, nodeV.y!, nodeV.width, nodeV.height), p1));
    edge.points.add(util.intersectRect(GraphRect(nodeW.x!, nodeW.y!, nodeW.width, nodeW.height), p2));
  }
}

void _fixupEdgeLabelCoords(Graph g) {
  for (var e in g.edgesIterable) {
    var edge = g.edge2<EdgeProps>(e);
    var xValue = edge.x;
    if (xValue != null) {
      if (edge.labelPos == LabelPosition.left || edge.labelPos == LabelPosition.right) {
        edge.width -=edge.labelOffset;
      }

      LabelPosition lp = edge.labelPos;
      if (lp == LabelPosition.left) {
        edge.x = xValue - (edge.width / 2 + edge.labelOffset);
      } else if (lp == LabelPosition.right) {
        edge.x = xValue + (edge.width / 2 + edge.labelOffset);
      }
    }
  }
}

void _reversePointsForReversedEdges(Graph g) {
  for (var e in g.edgesIterable) {
    var edge = g.edge2<EdgeProps>(e);
    if (edge.reversed==true) {
      edge.points = List.from(edge.points.reversed);
    }
  }
}

void _removeBorderNodes(Graph g) {
  for (var v in g.nodesIterable) {
    if (g.children(v).isNotEmpty) {
      var node = g.node<NodeProps>(v);
      var t = g.node<NodeProps>(node.borderTop!);
      var b = g.node<NodeProps>(node.borderBottom!);
      var l = g.node<NodeProps>(node.borderLeft.last);
      var r = g.node<NodeProps>(node.borderRight.last);

      node.width = (r.x! - l.x!).abs();
      node.height = (b.y! - t.y!).abs();
      node.x = l.x! + node.width / 2;
      node.y = t.y! + node.height / 2;
    }
  }

  for (var v in g.nodes) {
    if (g.node<NodeProps>(v).dummy == Dummy.border) {
      g.removeNode(v);
    }
  }
}

void _removeSelfEdges(Graph g) {
  for (var e in g.edges) {
    if (e.v == e.w) {
      var node = g.node<NodeProps>(e.v);
      node.selfEdges.add(SelfEdgeData(e, g.edge2<EdgeProps>(e)));
      g.removeEdge2(e);
    }
  }
}

void _insertSelfEdges(Graph g) {
  var layers = util.buildLayerMatrix(g);
  for (var layer in layers) {
    var orderShift = 0;
    layer.each((v, i) {
      var node = g.node<NodeProps>(v);
      node.order = i + orderShift;
      for (var selfEdge in node.selfEdges) {
        NodeProps np = NodeProps();
        np.width = selfEdge.data .width;
        np.height =selfEdge.data.height;
        np.rank = node.rank;
        np.order = i + (++orderShift);
        np.e = selfEdge.e;
        np.label = selfEdge.data;

        util.addDummyNode(g, Dummy.selfEdge, np, "_se");
      }
      node.selfEdges=[];
    });

  }
}

void _positionSelfEdges(Graph g) {
  for (var v in g.nodes) {
    var node = g.node<NodeProps>(v);
    if (node.dummy == Dummy.selfEdge) {
      var selfNode = g.node<NodeProps>(node.e!.v);
      var x = selfNode.x! + selfNode.width / 2;
      var y = selfNode.y!;
      var dx = node.x! - x;
      var dy = selfNode.height / 2;
      g.setEdge2(node.e!, node.label);
      g.removeNode(v);
      node.label?.points = [
        GraphPoint(x + 2 * dx / 3, y - dy),
        GraphPoint(x + 5 * dx / 6, y - dy),
        GraphPoint(x + dx, y),
        GraphPoint(x + 5 * dx / 6, y + dy),
        GraphPoint(x + 2 * dx / 3, y + dy)
      ];
      node.label?.x = node.x;
      node.label?.y = node.y;
    }
  }
}
