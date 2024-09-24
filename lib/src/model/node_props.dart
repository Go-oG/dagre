import 'package:dart_dagre/src/model/enums/dummy.dart';
import 'package:dart_dagre/src/model/enums/label_pos.dart';
import 'package:dart_dagre/src/model/edge_props.dart';
import '../graph/graph.dart';
import 'tmp/self_edge_data.dart';

class NodeProps {
  double? _x;
  double? _y;
  double width=0;
  double height=0;

  double? _weight;
  int? _order;
  int? _rank;
  int? _minRank;
  int? _maxRank;

  double? _out;
  double? _inner;

  double? _lim;
  double? _low;
  Dummy? _dummy;
  String? _parent;

  LabelPosition? _labelPos;
  EdgeProps? _label;
  EdgeObj? _edgeObj;
  EdgeProps? _edgeLabel;
  EdgeObj? _e;
  String? _v;

  String? borderType;
  String? borderTop;
  String? borderBottom;
  List<String> borderLeft = [];
  List<String> borderRight = [];
  List<SelfEdgeData> selfEdges = [];

  NodeProps({double? width, double? height}) {
    if (width != null) {
      this.width = width;
    }
    if (height != null) {
      this.height = height;
    }
  }

  double get x => _x!;

  double get y => _y!;

  double get weight => _weight!;

  int get order => _order!;

  int get rank => _rank!;

  int get minRank => _minRank!;

  int get maxRank => _maxRank!;

  double get out => _out!;

  double get inner => _inner!;

  double get lim => _lim!;

  double get low => _low!;

  String get parent => _parent!;

  LabelPosition get labelPos => _labelPos!;

  String get v => _v!;

  Dummy get dummy => _dummy!;

  EdgeProps get label => _label!;

  EdgeProps get edgeLabel => _edgeLabel!;

  EdgeObj get e => _e!;

  EdgeObj get edgeObj => _edgeObj!;

  double? get xNull => _x;

  double? get yNull => _y;

  int? get rankNull => _rank;

  int? get minRankNull => _minRank;

  int? get maxRankNull => _maxRank;

  double? get outNull => _out;

  double? get innerNull => _inner;

  double? get limNull => _lim;

  String? get parentNull => _parent;

  LabelPosition? get labelPosNull => _labelPos;

  Dummy? get dummyNull => _dummy;

  EdgeProps? get labelNull => _label;

  EdgeProps? get edgeLabelNull => _edgeLabel;

  EdgeObj? get eNull => _e;

  EdgeObj? get edgeObjNull => _edgeObj;


  set x(double? v) => _x = v;

  set y(double? v) => _y = v;

  set weight(double v) => _weight = v;

  set order(int v) => _order = v;

  set rank(int v) => _rank = v;

  set minRank(int v) => _minRank = v;

  set maxRank(int v) => _maxRank = v;

  set out(double v) => _out = v;

  set inner(double v) => _inner = v;

  set lim(double v) => _lim = v;

  set low(double v) => _low = v;

  set parent(String? v) => _parent = v;

  set labelPos(LabelPosition v) => _labelPos = v;

  set v(String? v) => _v = v;

  set dummy(Dummy? v) => _dummy = v;

  set label(EdgeProps? v) => _label = v;

  set edgeLabel(EdgeProps? v) => _edgeLabel = v;

  set e(EdgeObj? v) => _e = v;

  set edgeObj(EdgeObj v) => _edgeObj = v;


  @override
  String toString() {
    return '[x:$_x y:$_y w: $width h:$height rank:$_rank order:$_order]';
  }
}
