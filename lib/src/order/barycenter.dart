import 'package:dagre/src/model/edge.dart';

import '../graph/graph.dart';
import '../model/tmp/order_inner_result.dart';

List<OrderInnerResult> barycenter(Graph g, List<String> movable) {
  List<OrderInnerResult> r= List.from(movable.map((v) {
    List<Edge> inV = g.inEdges(v);
    if (inV.isEmpty) {
      return OrderInnerResult(v);
    } else {
      Map<String, num> initP = {'sum': 0, 'weight': 0};
      Map<String, num> result = initP;
      for (int i = 0; i < inV.length; i++) {
        var edge = g.edge(inV[i]);
        var nodeU = g.node(inV[i].v);
        num sum = result['sum']! + (edge.weight * nodeU.order);
        num weight = result['weight']! + edge.weight;
        result = {'sum': sum, 'weight': weight};
      }
      OrderInnerResult p = OrderInnerResult(v);
      p.barycenter = result['sum']! / result['weight']!;
      p.weight = result['weight']!;
      return p;
    }
  }));
  return r;
}
