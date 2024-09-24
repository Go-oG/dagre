import 'package:dart_dagre/src/model/node_props.dart';
import 'package:dart_dagre/src/util/list_util.dart';
import 'package:flutter/widgets.dart';
import '../model/edge_props.dart';

///v:sourceId or edgeEndNodeId
/// w=> targetId or edgeStartNodeId
/// name => edgeId
class Graph {
  static const String _defaultEdgeId = "\x00";
  static const String _edgeKeyDelim = "\x01";
  static const String _graphNodeId = "\x00";
  final bool isDirected;
  final bool isMultiGraph;
  final bool isCompound;

  // 图本身的属性
  dynamic _label;

  //v->label
  final Map<String, dynamic> _nodes = {};

  // v-> edgeObj
  final Map<String, Map<String, EdgeObj>> _in = {};

  // u -> v -> Number
  final Map<String, Map<String, int>> _preds = {};

  // v -> edgeObj
  final Map<String, Map<String, EdgeObj>> _out = {};

  // v -> w -> Number
  final Map<String, Map<String, int>> _sucs = {};

  // edgeId -> EdgeObj
  final Map<String, EdgeObj> _edgeObjs = {};

  // edgeId -> EdgeValue
  final Map<String, dynamic> _edgeLabels = {};

  // nodeId -> edgeObj
  Map<String, String> _parent = {};

  Map<String, Map<String, bool>> _children = {};

  int _nodeCount = 0;
  int _edgeCount = 0;

  dynamic Function(String) _defaultNodeLabelFun = (id) {
    return null;
  };

  Object Function(String, String, String?) _defaultEdgeLabelFun = (v, w, id) {
    return EdgeProps(v: v, w: w, id: id);
  };

  Graph({
    this.isDirected = true,
    this.isMultiGraph = false,
    this.isCompound = false,
  }) {
    if (isCompound) {
      _parent = {};
      _children = {};
      _children[_graphNodeId] = {};
    }
  }

  ///该数据可能有问题
  Graph setLabel(dynamic label) {
    _label = label;
    return this;
  }

  Graph setDefaultNodePropsFun(dynamic Function(String) newDefault) {
    _defaultNodeLabelFun = newDefault;
    return this;
  }

  Graph setDefaultEdgePropsFun(Object Function(String, String, String?) newDefault) {
    _defaultEdgeLabelFun = newDefault;
    return this;
  }

  R getLabel<R>() {
    return _label as R;
  }

  int get nodeCount => _nodeCount;

  List<String> get nodes => List.from(_nodes.keys);

  Iterable<String> get nodesIterable => _nodes.keys;

  List<String> get sources {
    return nodes.filter((v) {
      var t = _in[v];
      return t == null;
    });
  }

  List<String> get sinks {
    return nodes.filter((v) {
      return _out[v] == null;
    });
  }

  Graph setNodes(List<String> vs, [dynamic value]) {
    var self = this;
    vs.each((v, i) {
      self.setNode(v, value);
    });
    return this;
  }

  Graph setNode(String v, [dynamic value]) {
    if (_nodes.containsKey(v)) {
      if (value != null) {
        _nodes[v] = value;
      }
      return this;
    }

    _nodes[v] = value ?? _defaultNodeLabelFun.call(v);

    if (isCompound) {
      _parent[v] = _graphNodeId;
      _children[v] = {};
      Map<String, bool> m = _children[_graphNodeId] ?? {};
      _children[_graphNodeId] = m;
      m[v] = true;
    }
    _in[v] = {};
    _preds[v] = {};
    _out[v] = {};
    _sucs[v] = {};
    ++_nodeCount;
    return this;
  }

  R node<R>(String nodeId) {
    return _nodes[nodeId] as R;
  }

  bool hasNode(String? v) {
    return _nodes.containsKey(v);
  }

  Graph removeNode(String? v) {
    if (_nodes.containsKey(v)) {
      _nodes.remove(v);
      if (isCompound) {
        _removeFromParentsChildList(v);
        _parent.remove(v);
        children(v).forEach((child) {
          setParent(child);
        });
        _children.remove(v);
      }

      List<String> kl = List.from((_in[v] ?? {}).keys);
      for (var e in kl) {
        removeEdge2(_edgeObjs[e]);
      }
      _in.remove(v);
      _preds.remove(v);

      kl = List.from((_out[v] ?? {}).keys);
      for (var e in kl) {
        removeEdge2(_edgeObjs[e]);
      }
      _out.remove(v);
      _sucs.remove(v);
      --_nodeCount;
    }
    return this;
  }

  Graph setParent(String id, [String? parent]) {
    if (!isCompound) {
      throw FlutterError("Cannot set parent in a non-compound graph");
    }
    if (parent == null) {
      parent = _graphNodeId;
    } else {
      String? ancestor = parent;
      while (ancestor != null) {
        ancestor = this.parent(ancestor);
        if (ancestor == id) {
          throw FlutterError('Setting  $parent   as parent of $id  would create a cycle');
        }
      }
      setNode(parent);
    }
    setNode(id);
    _removeFromParentsChildList(id);
    _parent[id] = parent;

    Map<String, bool> m = _children[parent] ?? {};
    _children[parent] = m;
    m[id] = true;
    return this;
  }

  void _removeFromParentsChildList(String? v) {
    _children[_parent[v]]?.remove(v);
  }

  String? parent(String? v) {
    if (isCompound) {
      var parent = _parent[v];
      if (parent != _graphNodeId) {
        return parent;
      }
    }
    return null;
  }

  List<String> children([String? nodeId = _graphNodeId]) {
    if (isCompound) {
      var children = _children[nodeId];
      if (children != null) {
        return List.from(children.keys);
      }
    } else if (nodeId == _graphNodeId) {
      return nodes;
    } else if (hasNode(nodeId)) {
      return [];
    }
    return [];
  }

  List<String> predecessors(String v) {
    var predsV = _preds[v];
    if (predsV != null) {
      return List.from(predsV.keys);
    }
    return [];
  }

  List<String> successors(String v) {
    var sucsV = _sucs[v];
    if (sucsV != null) {
      return List.from(sucsV.keys);
    }
    return [];
  }

  List<String> neighbors(String v) {
    var preds = predecessors(v);
    if (preds.isNotEmpty) {
      Set<String> ds = Set.from(preds);
      successors(v).forEach((e) {
        ds.add(e);
      });
      return List.from(ds);
    }
    return [];
  }

  bool isLeaf(v) {
    List<String> neighborsv;
    if (isDirected) {
      neighborsv = successors(v);
    } else {
      neighborsv = neighbors(v);
    }
    return neighborsv.isEmpty;
  }

  Graph filterNodes(bool Function(String) filter) {
    var copy = Graph(isDirected: isDirected, isMultiGraph: isMultiGraph, isCompound: isCompound);
    copy.setLabel(getLabel());

    _nodes.forEach((v, value) {
      if (filter(v)) {
        copy.setNode(v, value);
      }
    });

    _edgeObjs.forEach((s, e) {
      if (copy.hasNode(e.v) && copy.hasNode(e.w)) {
        copy.setEdge2(e, edge(e.v, e.w, e.id));
      }
    });

    Map<String, String?> parents = {};
    findParent(v) {
      var parent = this.parent(v);
      if (parent == null || copy.hasNode(parent)) {
        parents[v] = parent;
        return parent;
      } else if (parents.containsKey(parent)) {
        return parents[parent];
      } else {
        return findParent(parent);
      }
    }

    if (isCompound) {
      for (var v in copy.nodes) {
        copy.setParent(v, findParent(v));
      }
    }
    return copy;
  }

  int get edgeCount => _edgeCount;

  ///返回所有的EdgeObj对象
  List<EdgeObj> get edges {
    return List.from(_edgeObjs.values);
  }

  Iterable<EdgeObj> get edgesIterable {
    return _edgeObjs.values;
  }

  ///根据EdgeObj 对象获取对应的Value
  R edge<R>(String v, String? w, [String? edgeId]) {
    var e = edgeArgsToId(isDirected, v, w, edgeId);
    return _edgeLabels[e] as R;
  }

  R edge2<R>(EdgeObj obj) {
    return edge(obj.v, obj.w, obj.id);
  }

  Graph setPath(List<String> idList, [EdgeProps? value]) {
    for (int i = 1; i < idList.length; i++) {
      String v = idList[i - 1];
      String w = idList[i];
      _setEdgeInner(v, w, null, value);
    }
    return this;
  }

  Graph setEdge2(EdgeObj edge, [dynamic value]) {
    return _setEdgeInner(edge.v, edge.w, edge.id, value);
  }

  Graph setEdge(String v, String w, {String? id, dynamic value}) {
    return _setEdgeInner(v, w, id, value);
  }

  Graph _setEdgeInner(String v, String w, String? edgeId, dynamic value) {
    var e = edgeArgsToId(isDirected, v, w, edgeId);
    if (_edgeLabels.containsKey(e)) {
      if (value != null) {
        _edgeLabels[e] = value;
      }
      return this;
    }
    if (!(edgeId == null || edgeId.isEmpty) && !isMultiGraph) {
      throw FlutterError("Cannot set a named edge when isMultigraph = false");
    }
    setNode(v);
    setNode(w);
    _edgeLabels[e] = value ?? _defaultEdgeLabelFun.call(v, w, edgeId);
    var edgeObj = edgeArgsToObj(isDirected, v, w, edgeId);
    v = edgeObj.v;
    w = edgeObj.w;
    _edgeObjs[e] = edgeObj;
    incrementOrInitEntry(_preds[w]!, v);
    incrementOrInitEntry(_sucs[v]!, w);

    var map = _in[w] ?? {};
    _in[w] = map;
    map[e] = edgeObj;

    map = _out[v] ?? {};
    _out[v] = map;
    map[e] = edgeObj;
    _edgeCount++;
    return this;
  }

  bool hasEdge(EdgeObj edge) {
    var e = edgeObjToId(isDirected, edge);
    return _edgeObjs[e] != null;
  }

  bool hasEdge2(String v, String w, [String? id]) {
    var e = edgeArgsToId(isDirected, v, w, id);
    return _edgeObjs[e] != null;
  }

  Graph removeEdge(String v, String w, [String? edgeId]) {
    var e = edgeArgsToId(isDirected, v, w, edgeId);
    var edge = _edgeObjs[e];
    if (edge != null) {
      v = edge.v;
      w = edge.w;
      _edgeLabels.remove(e);
      _edgeObjs.remove(e);
      decrementOrRemoveEntry(_preds[w], v);
      decrementOrRemoveEntry(_sucs[v], w);
      _in[w]?.remove(e);
      _out[v]?.remove(e);
      _edgeCount--;
    }
    return this;
  }

  Graph removeEdge2(EdgeObj? v) {
    if (v == null) {
      return this;
    }
    return removeEdge(v.v, v.w, v.id);
  }

  List<EdgeObj> inEdges(String v, [String? u]) {
    var inV = _in[v];
    if (inV != null && inV.isNotEmpty) {
      List<EdgeObj> edges = List.from(inV.values);
      if (u == null) {
        return edges;
      }
      return edges.filter((edge) {
        return edge.v == u;
      });
    }
    return [];
  }

  List<EdgeObj> outEdges(String v, [String? w]) {
    var outV = _out[v];
    if (outV != null) {
      List<EdgeObj> edges = List.from(outV.values);
      if (w == null) {
        return edges;
      }
      return edges.filter((edge) {
        return edge.w == w;
      });
    }
    return [];
  }

  List<EdgeObj> nodeEdges(String v, [String? w]) {
    var values = inEdges(v, w);
    if (values.isNotEmpty) {
      return [...values, ...outEdges(v, w)];
    }
    return [];
  }

  void incrementOrInitEntry(Map<String, int> map, String k) {
    int? v = map[k];
    if (v != null) {
      map[k] = v + 1;
    } else {
      map[k] = 1;
    }
  }

  void decrementOrRemoveEntry(Map<String, int>? map, String k) {
    if (map == null) {
      return;
    }
    int? v = map[k];
    if (v != null) {
      v -= 1;
      map[k] = v;
    }
    if (v == null || v == 0) {
      map.remove(k);
    }
  }

  String edgeArgsToId(bool isDirected, String v_, String? w_, [String? edgeId]) {
    String v = v_;
    String w = w_ ?? '';
    int t = v.compareTo(w);
    if (!isDirected && t > 0) {
      var tmp = v;
      v = w;
      w = tmp;
    }
    return v + _edgeKeyDelim + w + _edgeKeyDelim + ((edgeId == null || edgeId.isEmpty) ? _defaultEdgeId : edgeId);
  }

  EdgeObj edgeArgsToObj(bool isDirected, String v_, String w_, [String? edgeId]) {
    var v = v_;
    var w = w_;
    int t = v.compareTo(w);
    if (!isDirected && t > 0) {
      var tmp = v;
      v = w;
      w = tmp;
    }
    return EdgeObj(v: v, w: w, id: edgeId);
  }

  String edgeObjToId(bool isDirected, EdgeObj obj) {
    return edgeArgsToId(isDirected, obj.v, obj.w, obj.id);
  }
}

class EdgeObj {
  String v;
  String w;
  String? id;

  EdgeObj({required this.v, required this.w, this.id});
}
