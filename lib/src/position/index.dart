import 'package:dart_dagre/src/model/node_props.dart';

import '../graph/graph.dart';
import '../model/graph_props.dart';
import '../util.dart' as util;
import '../util/list_util.dart';
import 'bk.dart';

void position(Graph g) {
  g = util.asNonCompoundGraph(g);
  positionY(g);
  positionX(g).forEach((x, v) {
    g.node<NodeProps>(x).x = v;
  });
}

void positionY(Graph g) {
  List<List<String>> layering = util.buildLayerMatrix(g);
  var rankSep = g.getLabel<GraphProps>().rankSep;
  num prevY = 0;
  for (var layer in layering) {
    var maxHeight = max<num>(List.from(layer.map((v) {
      return g.node(v).height;
    })))??0;
    for (var v in layer) {
      g.node(v).y = prevY + maxHeight / 2;
    }

    prevY += maxHeight + rankSep;
  }
}
