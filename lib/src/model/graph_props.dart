import 'package:dagre/src/model/enums/acyclicer.dart';
import 'package:dagre/src/model/enums/align.dart';
import 'package:dagre/src/model/enums/rank_dir.dart';

import 'enums/ranker.dart';

class GraphProps {
  ///控制布局方向和对齐
  RankDir rankDir = RankDir.ttb;
  GraphAlign? align;
  ///节点水平之间的间距
  num marginX = 0;

  ///节点竖直之间的间距
  num marginY = 0;

  /// 不同rank层之间的间距
  num rankSep = 50;

  ///边之间的水平间距
  num edgeSep = 10;

  ///节点之间水平间距
  num nodeSep = 50;

  ///控制查找图形时使用的方法
  Acyclicer acyclicer = Acyclicer.none;

  ///控制为图中每个节点分配层级的算法类型
  Ranker ranker=Ranker.networkSimplex;

  ///设置布局的宽度和高度
  num? width;
  num? height;

  String? root;
  String? nestingRoot;
  num? _nodeRankFactor;
  int? maxRank;
  List<String> dummyChains = [];

  num get nodeRankFactor => _nodeRankFactor!;

  set nodeRankFactor(num v) => _nodeRankFactor = v;

}
