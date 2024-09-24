import 'package:dart_dagre/src/rank/util.dart' as ru;
import '../graph/graph.dart';
import '../model/enums/ranker.dart';
import '../model/graph_props.dart';
import 'feasible_tree.dart' as ft;
import 'network_simplex.dart';

void rank(Graph g) {
  Ranker ranker = g.getLabel<GraphProps>().ranker;
  if (ranker == Ranker.tightTree) {
    _tightTreeRanker(g);
    return;
  }
  if (ranker == Ranker.longestPath) {
    ru.longestPath(g);
    return;
  }
  _networkSimplexRanker(g);
}

void _tightTreeRanker(Graph g) {
  ru.longestPath(g);
  ft.feasibleTree(g);
}

void _networkSimplexRanker(Graph g) {
  networkSimplex(g);
}
