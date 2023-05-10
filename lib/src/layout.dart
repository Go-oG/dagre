import 'dart:math' as math;
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

void layout(Graph g) {
  var layoutGraph = _buildLayoutGraph(g);
  _runLayout(layoutGraph);
  _updateInputGraph(g, layoutGraph);
}

void _runLayout(Graph g) {
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
  order(g);
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
    var inputLabel = inputGraph.nodeNull(v);
    var layoutLabel = layoutGraph.node(v);

    if (inputLabel != null) {
      inputLabel.x = layoutLabel.x;
      inputLabel.y = layoutLabel.y;

      if (layoutGraph.children(v).isNotEmpty) {
        inputLabel.width = layoutLabel.width;
        inputLabel.height = layoutLabel.height;
      }
    }
  }

  for (var e in inputGraph.edges) {
    var inputLabel = inputGraph.edge(e);
    var layoutLabel = layoutGraph.edge(e);

    inputLabel.points = layoutLabel.points;
    if (layoutLabel.xNull != null) {
      inputLabel.x = layoutLabel.x;
      inputLabel.y = layoutLabel.y;
    }
  }

  inputGraph.graph.width = layoutGraph.graph.width;
  inputGraph.graph.height = layoutGraph.graph.height;
}

Graph _buildLayoutGraph(Graph inputGraph) {
  var g = Graph(isMultiGraph: true, isCompound: true);
  var graph = inputGraph.graph;
  GraphProps gp = GraphProps();
  gp.rankSep = graph.rankSep;
  gp.edgeSep = graph.edgeSep;
  gp.nodeSep = graph.nodeSep;
  gp.rankDir = graph.rankDir;
  gp.marginX = graph.marginX;
  gp.marginY = graph.marginY;

  gp.acyclicer = graph.acyclicer;
  gp.ranker = graph.ranker;
  gp.rankDir = graph.rankDir;
  gp.align = graph.align;

  g.setGraph(gp);

  for (var v in inputGraph.nodes) {
    var node = inputGraph.nodeNull(v) ?? NodeProps();
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
    EdgeProps? edge = inputGraph.edgeOrNull(e.v, e.w, e.id);
    if(edge==null){
      g.setEdge2(e, EdgeProps());
    }else{
      EdgeProps ep = EdgeProps();
      ep.minLen = edge.minLen;
      ep.weight = edge.weight;
      ep.width =edge.width;
      ep.height = edge.height;
      ep.labelOffset = edge.labelOffset;
      ep.labelPos = edge.labelPos;
      g.setEdge2(e, ep);
    }
  }

  return g;
}

void _makeSpaceForEdgeLabels(Graph g) {
  var graph = g.graph;
  graph.rankSep /= 2;
  g.edges.each((e, p1) {
    var edge = g.edge(e);
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
  for (var e in g.edges) {
    var edge = g.edge(e);
    if (edge.width != 0 && edge.height != 0) {
      var v = g.node(e.v);
      var w = g.node(e.w);
      var label = NodeProps();
      label.rank = ((w.rank - v.rank) / 2 + v.rank).toInt();
      label.e = e;
      util.addDummyNode(g, Dummy.edgeProxy, label, "_ep");
    }
  }
}

void _assignRankMinMax(Graph g) {
  num maxRank = 0;
  for (var v in g.nodes) {
    var node = g.node(v);
    if (node.borderTop != null) {
      node.minRank = g.node(node.borderTop!).rank;
      node.maxRank = g.node(node.borderBottom!).rank;
      maxRank = math.max(maxRank, node.maxRank);
    }
  }
  g.graph.maxRank = maxRank.toInt();
}

void _removeEdgeLabelProxies(Graph g) {
  for (var v in g.nodes) {
    var node = g.node(v);
    if (node.dummyNull == Dummy.edgeProxy) {
      g.edge(node.e).labelRank = node.rank;
      g.removeNode(v);
    }
  }
}

void _translateGraph(Graph g) {
  var minX = double.maxFinite;
  var maxX = 0;
  var minY = double.maxFinite;
  var maxY = 0;
  var graphLabel = g.graph;
  var marginX =graphLabel.marginX;
  var marginY =graphLabel.marginY;

  ///attrs is NodeProps or EdgeProps
  getExtremes(attrs) {
    num x = attrs.x;
    num y = attrs.y;
    num w = attrs.width;
    num h = attrs.height;
    minX = math.min(minX, x - w / 2);
    maxX = math.max(maxX, (x + w / 2)).toInt();
    minY = math.min(minY, y - h / 2);
    maxY = math.max(maxY, (y + h / 2)).toInt();
  }

  for (var v in g.nodes) {
    getExtremes(g.node(v));
  }

  for (var e in g.edges) {
    var edge = g.edge(e);
    if (edge.xNull != null) {
      getExtremes(edge);
    }
  }

  minX -= marginX;
  minY -= marginY;

  for (var v in g.nodes) {
    var node = g.node(v);
    node.x -=  minX;
    node.y -=minY;
  }
  for (var e in g.edges) {
    var edge = g.edge(e);
    edge.points.each((p, p1) {
      p.x -= minX;
      p.y -= minY;
    });
    if (edge.xNull != null) {
      edge.x -=  minX;
    }
    if (edge.yNull != null) {
      edge.y -=  minY;
    }
  }
  graphLabel.width = maxX - minX + marginX;
  graphLabel.height = maxY - minY + marginY;
}

void _assignNodeIntersects(Graph g) {
  for (var e in g.edges) {
    var edge = g.edge(e);
    var nodeV = g.node(e.v);
    var nodeW = g.node(e.w);
    GraphPoint p1, p2;
    if (edge.points.isEmpty) {
      edge.points = [];
      p1 = GraphPoint(nodeW.x, nodeW.y);
      p2 = GraphPoint(nodeV.x, nodeV.y);
    } else {
      p1 = edge.points[0];
      p2 = edge.points[edge.points.length - 1];
    }

    edge.points.insert(0, util.intersectRect(GraphRect(nodeV.x, nodeV.y, nodeV.width, nodeV.height), p1));
    edge.points.add(util.intersectRect(GraphRect(nodeW.x, nodeW.y, nodeW.width, nodeW.height), p2));
  }
}

void _fixupEdgeLabelCoords(Graph g) {
  for (var e in g.edges) {
    var edge = g.edge(e);
    if (edge.xNull != null) {
      if (edge.labelPos == LabelPosition.left || edge.labelPos == LabelPosition.right) {
        edge.width -=edge.labelOffset;
      }
      LabelPosition lp = edge.labelPos;
      if (lp == LabelPosition.left) {
        edge.x -= - (edge.width / 2 + edge.labelOffset);
      } else if (lp == LabelPosition.right) {
        edge.x += (edge.width / 2 + edge.labelOffset);
      }
    }
  }
}

void _reversePointsForReversedEdges(Graph g) {
  for (var e in g.edges) {
    var edge = g.edge(e);
    if (edge.reversedNull!=null&&edge.reversed) {
      edge.points = List.from(edge.points.reversed);
    }
  }
}

void _removeBorderNodes(Graph g) {
  for (var v in g.nodes) {
    if (g.children(v).isNotEmpty) {
      var node = g.node(v);
      var t = g.node(node.borderTop!);
      var b = g.node(node.borderBottom!);
      var l = g.node(node.borderLeft.last);
      var r = g.node(node.borderRight.last);

      node.width = (r.x - l.x).abs();
      node.height = (b.y - t.y).abs();
      node.x = l.x + node.width / 2;
      node.y = t.y + node.height / 2;
    }
  }

  for (var v in g.nodes) {
    if (g.node(v).dummyNull == Dummy.border) {
      g.removeNode(v);
    }
  }
}

void _removeSelfEdges(Graph g) {
  for (var e in g.edges) {
    if (e.v == e.w) {
      var node = g.node(e.v);
      node.selfEdges.add(SelfEdgeData(e, g.edge(e)));
      g.removeEdge2(e);
    }
  }
}

void _insertSelfEdges(Graph g) {
  var layers = util.buildLayerMatrix(g);
  for (var layer in layers) {
    var orderShift = 0;
    layer.each((v, i) {
      var node = g.node(v);
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
      node.selfEdges.clear();
    });
  }
}

void _positionSelfEdges(Graph g) {
  for (var v in g.nodes) {
    var node = g.node(v);
    if (node.dummyNull == Dummy.selfEdge) {
      var selfNode = g.node(node.e.v);
      var x = selfNode.x + selfNode.width / 2;
      var y = selfNode.y;
      var dx = node.x - x;
      var dy = selfNode.height / 2;
      g.setEdge2(node.e, node.label);
      g.removeNode(v);
      node.label.points = [
        GraphPoint(x + 2 * dx / 3, y - dy),
        GraphPoint(x + 5 * dx / 6, y - dy),
        GraphPoint(x + dx, y),
        GraphPoint(x + 5 * dx / 6, y + dy),
        GraphPoint(x + 2 * dx / 3, y + dy)
      ];
      node.label.x = node.x;
      node.label.y = node.y;
    }
  }
}
