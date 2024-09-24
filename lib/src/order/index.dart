import 'package:dart_dagre/src/model/enums/relationship.dart';
import 'package:dart_dagre/src/model/graph_props.dart';
import 'package:dart_dagre/src/order/sort_subgraph.dart';
import 'package:dart_dagre/src/util/list_util.dart';
import '../graph/graph.dart';
import '../model/tmp/resolve_conflicts_result.dart';
import '../util.dart' as util;
import '../util/util.dart';
import 'add_subgraph_constraints.dart';
import 'cross_count.dart';
import 'init_order.dart';
import 'build_layer_graph.dart';

void order(Graph g) {
  var maxRank = util.maxRank(g)!;

  List<Graph> downLayerGraphs = _buildLayerGraphs(g, range(1, maxRank + 1), Relationship.inEdges);
  List<Graph> upLayerGraphs = _buildLayerGraphs(g, range(maxRank - 1, -1, -1), Relationship.outEdges);

  List<List<String>> layering = initOrder(g);
  _assignOrder(g, layering);

  num bestCC = double.maxFinite;
  List<List<String>> best = [];
  for (int i = 0, lastBest = 0; lastBest < 4; ++i, ++lastBest) {
    _sweepLayerGraphs((i % 2)!=0 ? downLayerGraphs : upLayerGraphs, i % 4 >= 2);
    layering = util.buildLayerMatrix(g);
    var cc = crossCount(g, layering);
    if (cc < bestCC) {
      lastBest = 0;
      best = _copyList(layering);
      bestCC = cc;
    }
  }
  _assignOrder(g, best);
}

List<Graph> _buildLayerGraphs(Graph g, List<int> ranks, Relationship ship) {
  return List.from(ranks.map((rank) {
    return buildLayerGraph(g, rank, ship);
  }));
}

void _sweepLayerGraphs(List<Graph> layerGraphs,bool biasRight) {
  var cg = Graph();
  for (var lg in layerGraphs) {
    var root = lg.getLabel<GraphProps>().root!;
    ResolveConflictsResult sorted = sortSubgraph(lg, root, cg, biasRight);
    sorted.vs.each((v, i) {
      lg.node(v).order = i;
    });
    addSubgraphConstraints(lg, cg, sorted.vs);
  }
}

void _assignOrder(Graph g, List<List<String>> layering) {
  for (var layer in layering) {
    layer.each((v, i) {
      g.node(v).order = i;
    });
  }
}

List<List<String>> _copyList(List<List<String>> list) {
  List<List<String>> rl = [];
  for (var ele in list) {
    rl.add(List.from(ele));
  }
  return rl;
}
