import 'package:dart_dagre/src/graph/graph.dart';
import 'package:dart_dagre/src/model/enums/dummy.dart';
import 'package:dart_dagre/src/model/edge_props.dart';
import 'package:dart_dagre/src/model/node_props.dart';
import 'package:dart_dagre/src/util.dart' as util;
import 'model/graph_point.dart';
import 'model/graph_props.dart';

void run(Graph g) {
  g.getLabel<GraphProps>().dummyChains = [];
  for (var edge in g.edges) {
    _normalizeEdge(g, edge);
  }
}

void _normalizeEdge(Graph g, EdgeObj e) {
  var v = e.v;
  int vRank = g.node(v).rank;
  var w = e.w;
  int wRank = g.node(w).rank;
  var name = e.id;
  var edgeLabel = g.edge2<EdgeProps>(e);
  var labelRank = edgeLabel.labelRank;
  if (wRank == vRank + 1) return;

  g.removeEdge2(e);

  String dummy;
  NodeProps attrs;
  int i = 0;
  for (++vRank; vRank < wRank; ++i, ++vRank) {
    edgeLabel.points = [];
    attrs = NodeProps();
    attrs.width = 0;
    attrs.height = 0;
    attrs.edgeLabel = edgeLabel;
    attrs.edgeObj = e;
    attrs.rank = vRank;

    dummy = util.addDummyNode(g, Dummy.edge, attrs, "_d");
    if (vRank == labelRank) {
      attrs.width = edgeLabel.width;
      attrs.height = edgeLabel.height;
      attrs.dummy = Dummy.edgeLabel;
      attrs.labelPos = edgeLabel.labelPos;
    }
    EdgeProps ep = EdgeProps.zero();
    ep.weight = edgeLabel.weight;
    g.setEdge(v, dummy, id: name, value: ep);

    if (i == 0) {
      g.getLabel<GraphProps>().dummyChains.add(dummy);
    }
    v = dummy;
  }
  g.setEdge(v, w, id: name, value: EdgeProps(weight: edgeLabel.weight));
}

void undo(Graph g) {
  for (var v in g.getLabel<GraphProps>().dummyChains) {
    NodeProps? node = g.node(v);
    EdgeProps origLabel = node!.edgeLabel!;
    g.setEdge2(node.edgeObj!, origLabel);
    while (node != null && node.dummy != null) {
      var w = g.successors(v)[0];
      g.removeNode(v);
      origLabel.points.add(GraphPoint(node.x!, node.y!));
      if (node.dummy == Dummy.edgeLabel) {
        origLabel.x = node.x;
        origLabel.y = node.y;
        origLabel.width = node.width;
        origLabel.height = node.height;
      }
      v = w;
      node = g.node(v);
    }
  }
}
