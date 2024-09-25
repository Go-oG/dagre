import 'package:dart_dagre/src/model/edge_props.dart';
import 'package:dart_dagre/src/model/node_props.dart';

import '../graph/graph.dart';
import '../model/tmp/order_inner_result.dart';

List<OrderInnerResult> barycenter(Graph g, List<String> movable) {
return List.from(movable.map((v) {
    List<EdgeObj> inV = g.inEdges(v);
    if (inV.isEmpty) {
      return OrderInnerResult(v);
    } else {
      Map<String, num> acc = {'sum': 0, 'weight': 0};
      for (int i = 0; i < inV.length; i++) {
        var tt = inV[i];
        EdgeProps edge = g.edge(tt.v, tt.w, tt.id);
        NodeProps nodeU = g.node(inV[i].v);

        num sum = acc['sum']! + (edge.weight * nodeU.order!);
        num weight = acc['weight']! + edge.weight;
        acc = {'sum': sum, 'weight': weight};
      }

      OrderInnerResult p = OrderInnerResult(v);
      p.barycenter = acc['sum']! / acc['weight']!;
      p.weight = acc['weight']!;
      return p;
    }
  }));
}
