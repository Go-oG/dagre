import 'package:dart_dagre/dart_dagre.dart';

void main() {
  Map<String, DagreNode> nodeMap = {};
  nodeMap["kspacey"] = (DagreNode("kspacey", width: 144, height: 100));
  nodeMap["swilliams"] = (DagreNode("swilliams", width: 160, height: 100));
  nodeMap["bpitt"] = (DagreNode("bpitt", width: 108, height: 100));
  nodeMap["hford"] = (DagreNode("hford", width: 168, height: 100));
  nodeMap["lwilson"] = (DagreNode("lwilson", width: 144, height: 100));
  nodeMap["kbacon"] = (DagreNode("kbacon", width: 121, height: 100));

  List<DagreEdge> edgeList = [];
  edgeList.add(DagreEdge(nodeMap["kspacey"]!, nodeMap["swilliams"]!));
  edgeList.add(DagreEdge(nodeMap["swilliams"]!, nodeMap["kbacon"]!));
  edgeList.add(DagreEdge(nodeMap["bpitt"]!, nodeMap["kbacon"]!));
  edgeList.add(DagreEdge(nodeMap["hford"]!, nodeMap["lwilson"]!));
  edgeList.add(DagreEdge(nodeMap["lwilson"]!, nodeMap["kbacon"]!));
  GraphConfig config = GraphConfig(rankDir: RankDir.ttb, align: GraphAlign.dtl);
  DagreResult result = layout(nodeMap.values.toList(), edgeList, config);
  print(result.toString());
}
