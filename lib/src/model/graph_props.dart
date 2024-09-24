import 'package:dart_dagre/src/model/enums/acyclicer.dart';
import 'package:dart_dagre/src/model/enums/align.dart';
import 'package:dart_dagre/src/model/enums/rank_dir.dart';

import 'enums/ranker.dart';

class GraphProps {
  ///控制布局方向和对齐
  RankDir rankDir = RankDir.ttb;
  GraphAlign? align;

  ///节点之间水平间距
  double nodeSep = 50;

  ///边之间的水平间距
  double edgeSep = 10;

  /// 不同rank层之间的间距
  double rankSep = 50;

  ///节点水平之间的间距
  double marginX = 0;

  ///节点竖直之间的间距
  double marginY = 0;

  ///控制查找图形时使用的方法
  Acyclicer acyclicer = Acyclicer.none;

  ///控制为图中每个节点分配层级的算法类型
  Ranker ranker=Ranker.networkSimplex;

  ///设置布局的宽度和高度
  double width=0;
  double height=0;

  String? root;
  String? nestingRoot;
  double? _nodeRankFactor;
  int? maxRank;
  List<String> dummyChains = [];

  double get nodeRankFactor => _nodeRankFactor!;

  set nodeRankFactor(double v) => _nodeRankFactor = v;

}
