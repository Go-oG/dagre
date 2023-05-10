import 'package:dart_dagre/src/model/edge.dart';
import 'package:dart_dagre/src/model/graph_props.dart';
import 'package:dart_dagre/src/model/node_props.dart';
import 'package:dart_dagre/src/util/list_util.dart';
import 'package:flutter/widgets.dart';

import '../model/edge_props.dart';

class Graph {
  static const String _defaultEdgeId = "\x00";
  static const String _edgeKeyDelim = "\x01";
  static const String _graphNodeId = "\x00";
  final bool isDirected;
  final bool isMultiGraph;
  final bool isCompound;

  // 图本身的属性
  GraphProps _props = GraphProps();

  // nodeId ->NodeValue
  final Map<String, NodeProps?> _nodeValues = {};

  // edgeId -> EdgeValue
  final Map<String, EdgeProps> _edgeLabels = {};

  // edgeId -> EdgeObj
  final Map<String, Edge> _edgeObjs = {};

  // nodeId -> NodeId -> Number
  final Map<String, Map<String, num>> _preds = {};

  // v -> w -> Number
  final Map<String, Map<String, num>> _sucs = {};

  // nodeId -> edgeObj
  final Map<String, Map<String, Edge>> _out = {};

  // nodeId -> edgeObj
  final Map<String, Map<String, Edge>> _in = {};

  Map<String, String> _parent = {};

  Map<String, Map<String, bool>> _children = {};

  int _nodeCount = 0;
  int _edgeCount = 0;

  NodeProps? Function(String) _defaultNodePropsFun = (a) {
    return null;
  };
  EdgeProps Function(Edge edge) _defaultEdgePropsFun = (a) {
    return EdgeProps();
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

  Graph setGraph(GraphProps label) {
    _props = label;
    return this;
  }

  Graph setDefaultNodePropsFun(NodeProps? Function(String) newDefault) {
    _defaultNodePropsFun = newDefault;
    return this;
  }

  Graph setDefaultEdgePropsFun(EdgeProps Function(Edge) newDefault) {
    _defaultEdgePropsFun = newDefault;
    return this;
  }

  GraphProps get graph {
    return _props;
  }

  int get nodeCount => _nodeCount;

  List<String> get nodes => List.from(_nodeValues.keys);

  List<String> get sources {
    return nodes.filter((v) {
      var t=_in[v];
      return t==null||t.isEmpty;
    });
  }

  List<String> get sinks {
    return nodes.filter((v) {
      var t=_out[v];
      return t==null||t.isEmpty;
    });
  }

  Graph setNodes(List<String> vs, [NodeProps? value]) {
    var self = this;
    vs.each((v, i) {
      self.setNode(v, value);
    });
    return this;
  }

  Graph setNode(String v, [NodeProps? p]) {
    if (_nodeValues.containsKey(v)) {
      if (p != null) {
        _nodeValues[v] = p;
      }
      return this;
    }

    _nodeValues[v] = p ?? _defaultNodePropsFun.call(v);

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

  NodeProps node(String v) {
    // NodeProps p=_nodeValues[nodeId]??NodeProps();
    // _nodeValues[nodeId]=p;
    return _nodeValues[v]!;
  }

  NodeProps? nodeNull(String nodeId) {
    return _nodeValues[nodeId];
  }

  bool hasNode(String? v) {
    return _nodeValues.containsKey(v);
  }

  Graph removeNode(String? v) {
    if (_nodeValues.containsKey(v)) {
      _nodeValues.remove(v);
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

  Graph setParent(String node, [String? parent]) {
    if (!isCompound) {
      throw FlutterError("Cannot set parent in a non-compound graph");
    }
    if (parent == null) {
      parent = _graphNodeId;
    } else {
      String? ancestor = parent;
      while (ancestor != null) {
        ancestor = this.parent(ancestor);
        if (ancestor == node) {
          throw FlutterError('Setting  $parent   as parent of $node  would create a cycle');
        }
      }
      setNode(parent);
    }
    setNode(node);
    _removeFromParentsChildList(node);
    _parent[node] = parent;
    Map<String, bool> m = _children[parent] ?? {};
    m[node] = true;
    _children[parent] = m;
    return this;
  }

  void _removeFromParentsChildList(String? v) {
    Map<String, bool>? m = _children[_parent[v]];
    m?.remove(v);
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

  List<String> children([String? nodeId]) {
    nodeId ??= _graphNodeId;
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
      List<String> rl = [];
      Set<String> ds = {};
      for (var e in preds) {
        if (!ds.contains(e)) {
          rl.add(e);
          ds.add(e);
        }
      }
      successors(v).forEach((e) {
        if (!ds.contains(e)) {
          rl.add(e);
          ds.add(e);
        }
      });
      return rl;
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
    copy.setGraph(graph);

    _nodeValues.forEach((v, value) {
      if (filter(v)) {
        copy.setNode(v, value);
      }
    });

    _edgeObjs.forEach((e, s) {
      if (copy.hasNode(s.v) && copy.hasNode(s.w)) {
        copy.setEdge2(s, edge(s));
      }
    });
    var parents = {};
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
  List<Edge> get edges {
    return List.from(_edgeObjs.values);
  }

  ///根据EdgeObj 对象获取对应的Value
  EdgeProps edge(Edge e) {
    return _edgeLabels[edgeObjToId(isDirected, e)]!;
  }

  EdgeProps edge2(String v, String? w, [String? id]) {
    return edgeOrNull(v, w, id)!;
  }

  EdgeProps? edgeOrNull(String v, String? w, [String? edgeId]) {
    var e = edgeArgsToId(isDirected, v, w, edgeId);
    return _edgeLabels[e];
  }

  Graph setPath(List<String> nodeList, [EdgeProps? value]) {
    for (int i = 1; i < nodeList.length; i++) {
      String pre = nodeList[i - 1];
      String now = nodeList[i];
      _setEdgeInner(pre, now, null, value);
    }
    return this;
  }

  Graph setEdge2(Edge edge, [EdgeProps? value]) {
    return _setEdgeInner(edge.v, edge.w, edge.id, value);
  }

  Graph setEdge(String v, String w, {String? id, EdgeProps? value}) {
    return _setEdgeInner(v, w, id, value);
  }

  Graph _setEdgeInner(String v, String w, String? edgeId, EdgeProps? value) {
    var e = edgeArgsToId(isDirected, v, w, edgeId);
    if (_edgeLabels.containsKey(e)) {
      if (value != null) {
        _edgeLabels[e] = value;
      }
      return this;
    }
    if (edgeId != null && !isMultiGraph) {
      throw FlutterError("Cannot set a named edge when isMultigraph = false");
    }
    setNode(v);
    setNode(w);
    _edgeLabels[e] = value ?? _defaultEdgePropsFun.call(Edge(v: v, w: w, id: edgeId));
    var edgeObj = edgeArgsToObj(isDirected, v, w, edgeId);
    // Ensure we add undirected edges in a consistent way.
    v = edgeObj.v;
    w = edgeObj.w;
    _edgeObjs[e] = edgeObj;
    incrementOrInitEntry(_preds[w]!, v);
    incrementOrInitEntry(_sucs[v]!, w);
    _in[w]![e] = edgeObj;
    _out[v]![e] = edgeObj;
    _edgeCount++;
    return this;
  }

  bool hasEdge(Edge edge) {
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

  Graph removeEdge2(Edge? v) {
    if (v == null) {
      return this;
    }
    return removeEdge(v.v, v.w, v.id);
  }

  List<Edge> inEdges(String v, [String? u]) {
    var inV = _in[v];
    if (inV != null) {
      List<Edge> edges = List.from(inV.values);
      if (u == null) {
        return edges;
      }
      return edges.filter((edge) {
        return edge.v == u;
      });
    }
    return [];
  }

  List<Edge> outEdges(String v, [String? w]) {
    var outV = _out[v];
    if (outV != null) {
      List<Edge> edges = List.from(outV.values);
      if (w == null) {
        return edges;
      }
      return edges.filter((edge) {
        return edge.w == w;
      });
    }
    return [];
  }

  List<Edge> nodeEdges(String v, [String? w]) {
    var inEdgesv = inEdges(v, w);
    if (inEdgesv.isNotEmpty) {
      return [...inEdgesv, ...outEdges(v, w)];
    }
    return [];
  }

  void incrementOrInitEntry(Map<String, num> map, String k) {
    if (map[k] != null) {
      map[k] = map[k]! + 1;
    } else {
      map[k] = 1;
    }
  }

  void decrementOrRemoveEntry(Map<String, num>? map, String k) {
    if (map == null) {
      return;
    }
    num? v = map[k];
    if (v != null) {
      map[k] = --v;
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
    return v + _edgeKeyDelim + w + _edgeKeyDelim + (edgeId ?? _defaultEdgeId);
  }

  Edge edgeArgsToObj(bool isDirected, String v_, String w_, [String? edgeId]) {
    var v = v_;
    var w = w_;
    int t = v.compareTo(w);
    if (!isDirected && t > 0) {
      var tmp = v;
      v = w;
      w = tmp;
    }
    return Edge(v: v, w: w, id: edgeId);
  }

  String edgeObjToId(bool isDirected, Edge edgeObj) {
    return edgeArgsToId(isDirected, edgeObj.v, edgeObj.w, edgeObj.id);
  }
}
