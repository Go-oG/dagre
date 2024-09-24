import 'package:dart_dagre/src/graph/graph.dart';
import 'package:dart_dagre/src/model/edge_props.dart';
import 'package:dart_dagre/src/model/enums/acyclicer.dart';
import 'package:dart_dagre/src/util/util.dart';

import 'greedy_fas.dart';
import 'model/graph_props.dart';

void run(Graph g) {
  double Function(EdgeObj) weightFn(Graph g2) {
    return (e) {
      return g2.edge2<EdgeProps>(e).weight;
    };
  }

  List<EdgeObj> fas = (g.getLabel<GraphProps>().acyclicer==Acyclicer.greedy ? greedyFAS(g, weightFn(g)) : dfsFAS(g));
  for (var e in fas) {
    var label = g.edge2<EdgeProps>(e);
    g.removeEdge2(e);
    label.forwardName = e.id;
    label.reversed = true;
    g.setEdge(e.w, e.v,value: label,id: uniqueId("rev"));
  }

}

List<EdgeObj> dfsFAS(Graph g) {
  List<EdgeObj> fas = [];
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
    var label = g.edge2<EdgeProps>(e);
    if (label.reversed==true) {
      g.removeEdge2(e);
      var forwardName = label.forwardName;
      label.reversed = null;
      label.forwardName = null;
      g.setEdge(e.w, e.v,value:label,id: forwardName);
    }
  }
}
