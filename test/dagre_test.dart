import 'package:dart_dagre/dart_dagre.dart';
import 'package:dart_dagre/src/model/props.dart';

void main() {
  DagreGraph graph = DagreGraph();
  graph.addNode2("kspacey", 144, 100);
  graph.addNode2("swilliams", 160, 100);
  graph.addNode2("bpitt", 108, 100);
  graph.addNode2("hford", 168, 100);
  graph.addNode2("lwilson", 144, 100);
  graph.addNode2("kbacon", 121, 100);

  graph.addEdge(DagreEdge("kspacey", "swilliams"));
  graph.addEdge(DagreEdge("swilliams", "kbacon"));
  graph.addEdge(DagreEdge("bpitt", "kbacon"));
  graph.addEdge(DagreEdge("hford", "lwilson"));
  graph.addEdge(DagreEdge("lwilson", "kbacon"));

  DagreConfig config = DagreConfig(rankDir: RankDir.ttb);
  var time = DateTime.now().millisecondsSinceEpoch;
  DagreResult result = layout(graph, config);
  print("耗时：${DateTime.now().millisecondsSinceEpoch - time}ms");
  print(result.toString());
}
