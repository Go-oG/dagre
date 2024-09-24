import 'package:dart_dagre/src/model/enums/dummy.dart';
import 'package:dart_dagre/src/model/enums/label_pos.dart';
import 'package:dart_dagre/src/model/edge_props.dart';
import '../graph/graph.dart';
import 'tmp/self_edge_data.dart';

class NodeProps {
  double? x;
  double? y;
  double width=-1;
  double height=-1;

  double? weight;
  int? order;
  int? rank;
  int? minRank;
  int? maxRank;

  double? out;
  double? inner;

  double? lim;
  double? low;
  Dummy? dummy;
  String? parent;

  LabelPosition? labelPos;
  EdgeProps? label;
  EdgeObj? edgeObj;
  EdgeProps? edgeLabel;
  EdgeObj? e;
  String? v;

  String? borderType;
  String? borderTop;
  String? borderBottom;
  List<String> borderLeft = [];
  List<String> borderRight = [];
  List<SelfEdgeData> selfEdges = [];

  NodeProps({
    this.x,
    this.y,
    this.width = -1,
    this.height = -1,
    this.weight,
    this.order,
    this.rank,
    this.minRank,
    this.maxRank,
    this.out,
    this.inner,
    this.lim,
    this.low,
    this.dummy,
    this.parent,
    this.labelPos,
    this.label,
    this.edgeObj,
    this.edgeLabel,
    this.e,
    this.v,
    this.borderType,
    this.borderTop,
    this.borderBottom,
  });

  @override
  String toString() {
    return '[x:$x y:$y w: $width h:$height rank:$rank order:$order]';
  }
}
