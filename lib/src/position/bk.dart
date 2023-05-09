import 'dart:math' as math;
import 'package:dagre/src/model/enums/align.dart';
import 'package:dagre/src/model/enums/dummy.dart';
import 'package:dagre/src/model/enums/label_pos.dart';
import 'package:dagre/src/model/edge.dart';
import 'package:dagre/src/model/edge_props.dart';
import 'package:dagre/src/model/node_props.dart';
import 'package:dagre/src/util/list_util.dart';

import '../graph/graph.dart';
import '../util/util.dart';
import 'package:dagre/src/util.dart' as util;

Map<String, Map<String, bool>> _findType1Conflicts(Graph g, List<List<String>> layering) {
  Map<String, Map<String, bool>> conflicts = {};
  visitLayer(prevLayer, List<String> layer) {
    num k0 = 0;
    int scanPos = 0;
    num prevLayerLength = prevLayer.length;
    var lastNode = layer.last;
    layer.each((v, i) {
      String? w = _findOtherInnerSegmentNode(g, v);
      num k1 = w != null ? g.node(w).order : prevLayerLength;
      if (w != null || v == lastNode) {
        layer.sublist(scanPos, i + 1).forEach((scanNode) {
          g.predecessors(scanNode).forEach((u) {
            var uLabel = g.node(u), uPos = uLabel.order;
            if ((uPos < k0 || k1 < uPos) && uLabel.dummyNull==null && g.node(scanNode).dummyNull!=null) {
              _addConflict(conflicts, u, scanNode);
            }
          });
        });
        scanPos = i + 1;
        k0 = k1;
      }
    });
    return layer;
  }
  layering.reduce(visitLayer);
  return conflicts;
}

Map<String, Map<String, bool>> _findType2Conflicts(Graph g, List<List<String>> layering) {
  Map<String, Map<String, bool>> conflicts = {};
  scan(List<String> south, int southPos, int southEnd, int? prevNorthBorder, num nextNorthBorder) {
    String v;
    range(southPos, southEnd).forEach((i) {
      v = south[i];
      if (g.node(v).dummyNull != null) {
        g.predecessors(v).forEach((u) {
          var uNode = g.node(u);
          if (uNode.dummyNull != null && (uNode.order < (prevNorthBorder ?? double.nan) || uNode.order > nextNorthBorder)) {
            _addConflict(conflicts, u, v);
          }
        });
      }
    });
  }

  visitLayer(List<String> north, List<String> south) {
    int prevNorthPos = -1;
    int? nextNorthPos;
    int southPos = 0;
    south.each((v, southLookahead) {
      if (Dummy.border == g.node(v).dummyNull) {
        var predecessors = g.predecessors(v);
        if (predecessors.isNotEmpty) {
          nextNorthPos = g.node(predecessors[0]).order;
          scan(south, southPos, southLookahead, prevNorthPos, nextNorthPos!);
          southPos = southLookahead;
          prevNorthPos = nextNorthPos!;
        }
      }
      scan(south, southPos, south.length, nextNorthPos, north.length);
    });
    return south;
  }

  layering.reduce2(visitLayer);
  return conflicts;
}

String? _findOtherInnerSegmentNode(Graph g, String v) {
  try{
    if (g.node(v).dummyNull != null) {
      return g.predecessors(v).firstWhere((u) {
        return g.node(u).dummyNull!=null;
      });
    }
  }catch(_){
  }

  return null;
}

void _addConflict(Map<String, Map<String, bool>> conflicts, String v, String w) {
  int t = v.compareTo(w);
  if (t > 0) {
    var tmp = v;
    v = w;
    w = tmp;
  }
  var conflictsV = conflicts[v];
  if (conflictsV == null) {
    conflicts[v] = conflictsV = {};
  }
  conflictsV[w] = true;
}

bool _hasConflict(Map<String,Map<String,bool>> conflicts, String v, String w) {
  int t = v.compareTo(w);
  if (t > 0) {
    var tmp = v;
    v = w;
    w = tmp;
  }
  return conflicts[v]?.containsKey(w)??false;
}

_InnerResult _verticalAlignment(
  Graph g,
  List<List<String>> layering,
  Map<String, Map<String, bool>> conflicts,
  List<String> Function(String) neighborFn,
) {
  Map<String, String> root = {}, align = {};
  Map<String, int> pos = {};
  for (var layer in layering) {
    layer.each((v, order) {
      root[v] = v;
      align[v] = v;
      pos[v] = order;
    });
  }

  for (var layer in layering) {
    var prevIdx = -1;
    for (var v in layer) {
      List<String> ws = neighborFn(v);
      if (ws.isNotEmpty) {
        ws.sort((a,b){
          return pos[a]!.compareTo(pos[b]!);
        });

        num mp = (ws.length - 1) / 2;
        for (int i = mp.floor(), il = mp.ceil(); i <= il; ++i) {
          var w = ws[i];
          if (align[v] == v &&
              prevIdx < pos[w]! &&
              !_hasConflict(conflicts, v, w)) {
            align[w] = v;
            align[v] = root[v] = root[w]!;
            prevIdx = pos[w]!;
          }
        }
      }
    }
  }
  _InnerResult result = _InnerResult();
  result.root = root;
  result.align = align;
  return result;
}

Map<String, num> _horizontalCompaction(
  Graph g,
  List<List<String>> layering,
  Map<String, String> root,
  Map<String, String> align,
  bool reverseSep,
) {
  Map<String, num> xs = {};
  Graph blockG = _buildBlockGraph(g, layering, root, reverseSep);
  String borderType = reverseSep ? "borderLeft" : "borderRight";

  iterate(void Function(String) setXsFunc,bool predecessors) {
    var stack = blockG.nodes;
    Map<String, bool> visited = {};

    while (stack.isNotEmpty) {
      String elem=stack.removeLast();
      if ((visited[elem] ?? false)) {
        setXsFunc.call(elem);
      } else {
        visited[elem] = true;
        stack.add(elem);
        if(predecessors){
          stack = stack.concat(blockG.predecessors(elem));
        }else{
          stack = stack.concat(blockG.successors(elem));
        }
      }
    }
  }

  // First pass, assign smallest coordinates
  pass1(String elem) {
    List<Edge> lp = blockG.inEdges(elem);
    xs[elem] = lp.reduce2<num>((e, acc) {
      return math.max(acc, (xs[e.v]! + blockG.edge(e).value));
    }, 0);
  }

  // Second pass, assign greatest coordinates
  pass2(String elem) {
    num minv = blockG.outEdges(elem).reduce2((e, acc) {
      return math.min(acc, xs[e.w]! - blockG.edge(e).value);
    }, double.maxFinite);

    var node = g.node(elem);
    if (minv != double.maxFinite && node.borderType != borderType) {
      xs[elem] = math.max(xs[elem] as num, minv);
    }
  }

  iterate(pass1, true);
  iterate(pass2, false);

  // Assign x coordinates to all nodes
  for (var v in align.values) {
    xs[v] = xs[root[v]]!;
  }
  return xs;
}

Graph _buildBlockGraph(Graph g, List<List<String>> layering, Map<String, String> root, bool reverseSep) {
  Graph blockGraph = Graph();
  var graphLabel = g.graph;
  var sepFn = _sep(graphLabel.nodeSep, graphLabel.edgeSep, reverseSep);
  for (var layer in layering) {
    String? u;
    for (var v in layer) {
      var vRoot = root[v]!;
      blockGraph.setNode(vRoot);
      if (u != null) {
        var uRoot = root[u]!;
        num? prevMax = blockGraph.edgeOrNull(uRoot, vRoot)?.value;
        EdgeProps p = EdgeProps();
        p.value = math.max(sepFn.call(g, v, u), prevMax??0);
        blockGraph.setEdge(uRoot, vRoot, value: p);
      }
      u = v;
    }
  }
  return blockGraph;
}

/*
 * 返回给定对齐中宽度最小的对齐
 */
Map<String, num> _findSmallestWidthAlignment(Graph g, Map<GraphAlign, Map<String, num>> xss) {
  return minBy(List.from(xss.values), (xs) {
    num max = double.minPositive;
    num min = double.maxFinite;
    xs.forEach((x, v) {
      var halfWidth = _width(g, x) / 2;
      max = math.max(v + halfWidth, max);
      min = math.min(v - halfWidth, min);
    });
    return max - min;
  });
}

void _alignCoordinates(Map<GraphAlign, Map<String, num>> xss, Map<String, num> alignTo) {
  List<num> alignToVals = List.from(alignTo.values);
  num alignToMin = min(alignToVals)!, alignToMax = max(alignToVals) !;
  for (var vert in ["u", "d"]) {
    for (var horiz in ["l", "r"]) {
      GraphAlign alignment = fromStr('${vert}t$horiz');
      Map<String, num> xs = xss[alignment]!;
      num delta;

      if (xs == alignTo){
        continue;
      }

      List<num> xsVals = List.from(xs.values);
      delta = horiz == "l" ? alignToMin - min(xsVals)! : alignToMax - max(xsVals)!;
      if (delta!=0) {
        Map<String, num> rm = {};
        xs.forEach((key, value) {
          rm[key] = value + delta;
        });
        xss[alignment] = rm;
      }
    }
  }
}

Map<String, num> _balance(Map<GraphAlign, Map<String, num>> xss, GraphAlign? align) {
  Map<String, num> ulMap = xss[GraphAlign.utl]!;
  Map<String, num> map = {};
  for (var key in ulMap.keys) {
    num d;
    if (align != null) {
      d = xss[align]![key]!;
    } else {
      List<num> xs=[];
      for(var ve in xss.values){
        num? rn=ve[key];
        if(rn!=null){
          xs.add(rn);
        }
      }
      xs.sort();
      d = (xs[1] + xs[2]) / 2;
    }
    map[key] = d;
  }
  return map;
}

Map<String, num> positionX(Graph g) {
  List<List<String>> layering = util.buildLayerMatrix(g);
  Map<String, Map<String, bool>> conflicts =_mergeMap( _findType1Conflicts(g, layering), _findType2Conflicts(g, layering));
  Map<GraphAlign, Map<String, num>> xss = {};
  List<List<String>> adjustedLayering;
  for (var vert in ["u", "d"]) {
    adjustedLayering = vert == "u" ? layering :  layering.reverse2();
    for (var horiz in ["l", "r"]) {
      if (horiz == "r") {
        adjustedLayering = List.from(adjustedLayering.map((inner) {
          return inner.reverse2();
        }));
      }
      List<String> Function(String) neighborFn = (vert == "u" ? g.predecessors : g.successors);
      _InnerResult align = _verticalAlignment(g, adjustedLayering, conflicts, neighborFn);
      Map<String, num> xs = _horizontalCompaction(g, adjustedLayering, align.root, align.align, horiz == "r");
      if (horiz == "r") {
        Map<String, num> rm = {};
        xs.forEach((key, value) {
          rm[key] = -value;
        });
        xs = rm;
      }
      xss[fromStr('${vert}t$horiz')] = xs;
    }
  }
  var smallestWidth = _findSmallestWidthAlignment(g, xss);
  _alignCoordinates(xss, smallestWidth);
  return _balance(xss, g.graph.align);
}

num Function(Graph, String, String) _sep(num nodeSep, num edgeSep, bool reverseSep) {
  return (Graph g, String v, String w) {
    NodeProps vLabel = g.node(v);
    NodeProps wLabel = g.node(w);
    num sum = 0;
    num delta = 0;
    sum += vLabel.width / 2;
    if (vLabel.labelPosNull == LabelPosition.left) {
      delta = -vLabel.width / 2;
    } else if (vLabel.labelPosNull == LabelPosition.right) {
      delta = vLabel.width / 2;
    }
    if (delta != 0) {
      sum += reverseSep ? delta : -delta;
    }
    delta = 0;
    sum += (vLabel.dummyNull != null ? edgeSep : nodeSep) / 2;
    sum += (wLabel.dummyNull != null ? edgeSep : nodeSep) / 2;
    sum += wLabel.width / 2;

    var lab = wLabel.labelPosNull;
    if (lab == LabelPosition.left) {
      delta = wLabel.width / 2;
    } else if (lab == LabelPosition.right) {
      delta = -wLabel.width / 2;
    }
    if (delta != 0) {
      sum += reverseSep ? delta : -delta;
    }
    delta = 0;
    return sum;
  };
}

num _width(Graph g, String v) {
  return g.node(v).width;
}

Map<String, Map<String, bool>> _mergeMap(Map<String, Map<String, bool>> m1,Map<String, Map<String, bool>> m2){
  Map<String, Map<String, bool>> map={};
  map.addAll(m1);
  m2.forEach((key, value) {
    Map<String,bool> cm=map[key]??{};
    map[key]=cm;
    cm.addAll(value);
  });
  return map;
}

class _InnerResult {
  Map<String, String> root = {};
  Map<String, String> align = {};
}

