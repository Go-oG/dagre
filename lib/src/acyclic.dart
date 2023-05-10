import 'package:dart_dagre/src/graph/graph.dart';
import 'package:dart_dagre/src/model/enums/acyclicer.dart';
import 'package:dart_dagre/src/model/edge.dart';
import 'package:dart_dagre/src/util/util.dart';

import 'greedy_fas.dart';

void run(Graph g) {
  num Function(Edge) weightFn(Graph g2) {
    return (e) {
      return g2.edge(e).weight;
    };
  }

  List<Edge> fas = (g.graph.acyclicer==Acyclicer.greedy ? greedyFAS(g, weightFn(g)) : dfsFAS(g));
  for (var e in fas) {
    var label = g.edge(e);
    g.removeEdge2(e);
    label.forwardName = e.id;
    label.reversed = true;
    g.setEdge(e.w, e.v,value: label,id: uniqueId("rev"));
  }
}

List<Edge> dfsFAS(Graph g) {
  List<Edge> fas = [];
  Map<String, bool> stack = {};
  Map<String, bool> visited = {};

  dfs(v) {
    if (visited.containsKey(v)) {
      return;
    }
    visited[v] = true;
    stack[v] = true;
    g.outEdges(v).forEach((e) {
      if (stack.containsKey(e.w)) {
        fas.add(e);
      } else {
        dfs(e.w);
      }
    });
    stack.remove(v);
  }

  g.nodes.forEach(dfs);
  return fas;
}

void undo(Graph g) {
  for (var e in g.edges) {
    var label = g.edge(e);
    if (label.reversedNull ?? false) {
      g.removeEdge2(e);
      var forwardName = label.forwardName;
      label.reversed = null;
      label.forwardName = null;
      g.setEdge(e.w, e.v,value:label,id: forwardName);
    }
  }
}
