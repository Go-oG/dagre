import 'package:dagre/src/model/enums/dummy.dart';
import 'package:dagre/src/model/enums/label_pos.dart';
import 'package:dagre/src/model/edge_props.dart';
import 'package:dagre/src/model/edge.dart';

import 'tmp/self_edge_data.dart';

class NodeProps {
  num? _x;
  num? _y;
  num width=0;
  num height=0;

  num? _weight;
  int? _order;
  int? _rank;
  int? _minRank;
  int? _maxRank;

  num? _out;
  num? _inner;

  num? _lim;
  num? _low;
  Dummy? _dummy;
  String? _parent;

  LabelPosition? _labelPos;
  EdgeProps? _label;
  Edge? _edgeObj;
  EdgeProps? _edgeLabel;
  Edge? _e;
  String? _v;

  String? borderType;
  String? borderTop;
  String? borderBottom;
  List<String> borderLeft = [];
  List<String> borderRight = [];
  List<SelfEdgeData> selfEdges = [];

  NodeProps({num? width, num? height}) {
    if (width != null) {
      this.width = width;
    }
    if (height != null) {
      this.height = height;
    }
  }

  num get x => _x!;

  num get y => _y!;

  num get weight => _weight!;

  int get order => _order!;

  int get rank => _rank!;

  int get minRank => _minRank!;

  int get maxRank => _maxRank!;

  num get out => _out!;

  num get inner => _inner!;

  num get lim => _lim!;

  num get low => _low!;

  String get parent => _parent!;

  LabelPosition get labelPos => _labelPos!;

  String get v => _v!;

  Dummy get dummy => _dummy!;

  EdgeProps get label => _label!;

  EdgeProps get edgeLabel => _edgeLabel!;

  Edge get e => _e!;

  Edge get edgeObj => _edgeObj!;

  num? get xNull => _x;

  num? get yNull => _y;

  int? get rankNull => _rank;

  int? get minRankNull => _minRank;

  int? get maxRankNull => _maxRank;

  num? get outNull => _out;

  num? get innerNull => _inner;

  num? get limNull => _lim;

  String? get parentNull => _parent;

  LabelPosition? get labelPosNull => _labelPos;

  Dummy? get dummyNull => _dummy;

  EdgeProps? get labelNull => _label;

  EdgeProps? get edgeLabelNull => _edgeLabel;

  Edge? get eNull => _e;

  Edge? get edgeObjNull => _edgeObj;


  set x(num? v) => _x = v;

  set y(num? v) => _y = v;

  set weight(num v) => _weight = v;

  set order(int v) => _order = v;

  set rank(int v) => _rank = v;

  set minRank(int v) => _minRank = v;

  set maxRank(int v) => _maxRank = v;

  set out(num v) => _out = v;

  set inner(num v) => _inner = v;

  set lim(num v) => _lim = v;

  set low(num v) => _low = v;

  set parent(String? v) => _parent = v;

  set labelPos(LabelPosition v) => _labelPos = v;

  set v(String? v) => _v = v;

  set dummy(Dummy? v) => _dummy = v;

  set label(EdgeProps? v) => _label = v;

  set edgeLabel(EdgeProps? v) => _edgeLabel = v;

  set e(Edge? v) => _e = v;

  set edgeObj(Edge v) => _edgeObj = v;


  @override
  String toString() {
    return '[x:$_x y:$_y w: $width h:$height rank:$_rank order:$_order]';
  }
}
