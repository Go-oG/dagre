import '../graph/graph.dart';
import '../util.dart' as util;
import '../util/list_util.dart';
import 'bk.dart';

void position(Graph g) {
  g = util.asNonCompoundGraph(g);
  positionY(g);
  positionX(g).forEach((x, v) {
    g.node(x).x = v;
  });
}

void positionY(Graph g) {
  List<List<String>> layering = util.buildLayerMatrix(g);
  var rankSep = g.graph.rankSep;
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
