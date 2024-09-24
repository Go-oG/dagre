import 'package:dart_dagre/src/model/graph_point.dart';

import 'enums/label_pos.dart';

class EdgeProps {
  double minLen = 1;
  double weight = 1;
  double width = 0;
  double height = 0;
  double labelOffset = 10;
  LabelPosition labelPos = LabelPosition.right;

  ///其它属性
  String? id;
  double? _x;
  double? _y;
  String? _v;
  String? _w;

  double? _barycenter;
  double? _cutValue;
  int? _labelRank;
  bool? _nestingEdge;
  bool? _reversed;
  String? _forwardName;
  double value = 0;
  List<GraphPoint> points = [];

  EdgeProps({
    String? id,
    String? v,
    String? w,
    double? weight,
    double? barycenter,
    double? minLen,
    double? cutValue,
    bool? nestingEdge,
    double? value,
  }) {
    if (id != null) {
      this.id = id;
    }
    if (v != null) {
      _v = v;
    }
    if (w != null) {
      _w = w;
    }
    if (weight != null) {
      this.weight = weight;
    }

    if (barycenter != null) {
      this.barycenter = barycenter;
    }
    if (minLen != null) {
      this.minLen = minLen;
    }
    if (cutValue != null) {
      _cutValue = cutValue;
    }
    if (nestingEdge != null) {
      _nestingEdge = nestingEdge;
    }
    if (value != null) {
      this.value = value;
    }
  }

  EdgeProps.zero() {
    minLen = 0;
    weight = 0;
    width = 0;
    height = 0;
    labelOffset = 0;
  }

  String get v => _v!;

  String get w => _w!;

  double get x => _x!;

  double get y => _y!;

  double get barycenter => _barycenter!;

  double get cutValue => _cutValue!;

  int get labelRank => _labelRank!;

  bool get nestingEdge => _nestingEdge!;

  bool get reversed => _reversed!;

  String get forwardName => _forwardName!;

  double? get xNull => _x;

  double? get yNull => _y;

  int? get labelRankNull => _labelRank;

  bool? get nestingEdgeNull => _nestingEdge;

  bool? get reversedNull => _reversed;

  set v(String? vv) => _v = vv;

  set w(String? vv) => _w = vv;

  set x(double? v) => _x = v;

  set y(double? v) => _y = v;

  set barycenter(double? v) => _barycenter = v;

  set cutValue(double? v) => _cutValue = v;

  set labelRank(int? v) => _labelRank = v;

  set nestingEdge(bool? v) => _nestingEdge = v;

  set reversed(bool? v) => _reversed = v;

  set forwardName(String? v) => _forwardName = v;

  EdgeProps copy() {
    EdgeProps p = EdgeProps();
    p.id = id;
    p._v = _v;
    p._w = _w;
    p._x = _x;
    p._y = _y;
    p.width = width;
    p.height = height;
    p.weight = weight;
    p._barycenter = _barycenter;
    p.minLen = minLen;
    p._cutValue = _cutValue;
    p._labelRank = _labelRank;
    p.labelPos = labelPos;
    p.labelOffset = labelOffset;
    p._nestingEdge = _nestingEdge;
    p._reversed = _reversed;
    p._forwardName = _forwardName;
    p.points = List.from(points);
    p.value = value;
    return p;
  }

  @override
  String toString() {
    return '[x:$_x,y:$_y, w:$width, h:$height  ]';
  }
}
