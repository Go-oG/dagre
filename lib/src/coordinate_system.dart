import 'package:dart_dagre/src/graph/graph.dart';
import 'package:dart_dagre/src/model/enums/rank_dir.dart';
import 'package:dart_dagre/src/model/graph_point.dart';
import 'package:dart_dagre/src/model/props.dart';

void adjust(Graph g) {
  var rankDir = g.label2?.rankDir;
  if (rankDir ==RankDir.ltr || rankDir ==RankDir.rtl) {
    _swapWidthHeight(g);
  }
}

void undo(Graph g) {
  var rankDir = g.label2?.rankDir;
  if (rankDir == RankDir.btt || rankDir ==RankDir.rtl) {
    _reverseY(g);
  }

  if (rankDir ==RankDir.ltr || rankDir ==RankDir.rtl) {
    _swapXY(g);
    _swapWidthHeight(g);
  }
}

void _swapWidthHeight(Graph g) {
  for (var v in g.nodesIterable) {
    _swapWidthHeightOne(g.node(v));
  }
  for (var e in g.edgesIterable) {
    _swapWidthHeightOne(g.edge2(e));
  }
}

void _swapWidthHeightOne(Props attrs) {
  var w = attrs.getD(widthK);
  attrs[widthK] = attrs[heightK];
  attrs[heightK] = w;
}

void _reverseY(Graph g) {
  for (var v in g.nodesIterable) {
    Props np = g.node(v);
    np[yK] = -np.getD(yK);
  }
  for (var e in g.edgesIterable) {
    var edge = g.edge2(e);
    for (var p in edge.get<List<GraphPoint>>(pointsK)) {
      p.y=-p.y;
    }
    var vv=edge.getD2(yK);
    if(vv!=null&&vv!=0){
      edge[yK] = -vv;
    }
  }
}

void _swapXY(Graph g) {
  for (var v in g.nodesIterable) {
    _swapXYOne(g.node(v));
  }

  for (var e in g.edgesIterable) {
    var edge = g.edge2(e);
    edge[pointsK]=List.from(edge.get<List<GraphPoint>>(pointsK).map((e) => GraphPoint(e.y, e.x)));
    var vv=edge.getD2(xK);
    if(vv!=null&&vv!=0){
      edge[xK] = edge[yK];
      edge[yK]=vv;
    }
  }
}

void _swapXYOne(Props attrs) {
  var vv = attrs[xK];
  attrs[xK] = attrs[yK];
  attrs[yK] = vv;
}
