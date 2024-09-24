import 'package:dart_dagre/src/model/graph_point.dart';

import 'enums/label_pos.dart';

class EdgeProps {
  double minLen;
  double weight;
  double width;
  double height;
  double labelOffset;
  LabelPosition labelPos;

  ///其它属性
  String? id;
  double? x;
  double? y;
  String? v;
  String? w;

  double? barycenter;
  double? cutValue;
  int? labelRank;
  bool? nestingEdge;
  bool? reversed;
  String? forwardName;
  double value = 0;
  List<GraphPoint> points = [];

  EdgeProps({
    this.minLen = 1,
    this.weight = 1,
    this.width = -1,
    this.height = -1,
    this.labelOffset = 10,
    this.labelPos = LabelPosition.right,
    this.id,
    this.v,
    this.w,
    this.barycenter,
    this.cutValue,
    this.nestingEdge,
    this.value = 0,
    this.forwardName,
  });

  EdgeProps.zero()
      : minLen = 0,
        weight = 0,
        width = 0,
        height = 0,
        labelPos = LabelPosition.center,
        labelOffset = 0;

  //
  // EdgeProps copy() {
  //   EdgeProps p = EdgeProps();
  //   p.id = id;
  //   p._v = _v;
  //   p._w = _w;
  //   p._x = _x;
  //   p._y = _y;
  //   p.width = width;
  //   p.height = height;
  //   p.weight = weight;
  //   p._barycenter = _barycenter;
  //   p.minLen = minLen;
  //   p._cutValue = _cutValue;
  //   p._labelRank = _labelRank;
  //   p.labelPos = labelPos;
  //   p.labelOffset = labelOffset;
  //   p._nestingEdge = _nestingEdge;
  //   p._reversed = _reversed;
  //   p._forwardName = _forwardName;
  //   p.points = List.from(points);
  //   p.value = value;
  //   return p;
  // }

  @override
  String toString() {
    return '[x:$x,y:$y, w:$width, h:$height  ]';
  }
}
