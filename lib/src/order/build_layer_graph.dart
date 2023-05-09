import 'package:dagre/src/model/edge_props.dart';
import 'package:dagre/src/model/graph_props.dart';
import 'package:dagre/src/model/node_props.dart';
import '../graph/graph.dart';
import '../model/enums/relationship.dart';
import '../model/edge.dart';
import '../util/util.dart';

Graph buildLayerGraph(Graph g, int rank, Relationship ship) {
  String root = _createRootNode(g);
  Graph result = Graph(isCompound: true);
  GraphProps gp = GraphProps();
  gp.root = root;
  result.setGraph(gp);
  result.setDefaultNodePropsFun((v) {
    return g.nodeNull(v);
  });

  for (var v in g.nodes) {
    NodeProps node = g.node(v);
    String? parent = g.parent(v);
    if (node.rankNull == rank || (node.minRankNull ?? double.nan) <= rank && rank <= (node.maxRankNull ?? double.nan)) {
      result.setNode(v);
      result.setParent(v, parent ?? root);
      List<Edge> tmpList = ship == Relationship.inEdges ? g.inEdges(v) : g.outEdges(v);
      for (var e in tmpList) {
        String u = e.v == v ? e.w : e.v;
        EdgeProps? edge = result.edgeOrNull(u, v);
        num weight =edge?.weight??0 ;
        EdgeProps ep = EdgeProps.zero();
        ep.weight = g.edge(e).weight + weight;
        result.setEdge(u, v, value: ep);
      }
      if (node.minRankNull != null) {
        NodeProps np = NodeProps();
        np.borderLeft = [node.borderLeft[rank]];
        np.borderRight = [node.borderRight[rank]];
        result.setNode(v, np);
      }
    }
  }
  return result;
}

String _createRootNode(Graph g) {
  String v = uniqueId('_root');
  while (g.hasNode(v)) {
    v = uniqueId('_root');
  }
  return v;
}
