import 'dart:math' as math;
import 'package:dart_dagre/src/graph/graph.dart';
import 'package:dart_dagre/src/model/edge_props.dart';
import 'package:dart_dagre/src/model/node_props.dart';
import 'package:dart_dagre/src/util/list_util.dart';
import 'package:dart_dagre/src/util/util.dart';

num Function(EdgeObj) defaultWeightFun = (a) {
  return 1;
};

List<EdgeObj> greedyFAS(Graph g, num Function(EdgeObj)? weightFn) {
  if (g.nodeCount <= 1) {
    return [];
  }
  _InnerResult2 state = _buildState(g, weightFn??defaultWeightFun);

  List<EdgeObj> results = _doGreedyFAS(state.graph, state.buckets, state.zeroIdx);

  // Expand multi-edges
  List<EdgeObj> rl = [];
  for (var e in results) {
    rl.addAll(g.outEdges(e.v, e.w));
  }
  return rl;
}

List<EdgeObj> _doGreedyFAS(Graph g, List<List<NodeProps>> buckets, int zeroIdx) {
  List<EdgeObj> results = [];
  var sources = buckets[buckets.length - 1];
  var sinks = buckets[0];
  NodeProps? entry;
  while (g.nodeCount > 0) {
    while (sinks.isNotEmpty) {
      entry=sinks.removeAt(0);
      _removeNode(g, buckets, zeroIdx, entry, false);
    }
    while (sources.isNotEmpty) {
      entry = sources.removeAt(0);
      _removeNode(g, buckets, zeroIdx, entry, false);
    }
    if (g.nodeCount > 0) {
      for (var i = buckets.length - 2; i > 0; --i) {
        var bl=buckets[i];
        entry = bl.isNotEmpty?bl.removeAt(0):null;
        if (entry != null) {
          results = results.concat(_removeNode(g, buckets, zeroIdx, entry, true));
          break;
        }
      }
    }
  }
  return results;
}

List<EdgeObj>? _removeNode(Graph g, List<List<NodeProps>> buckets, int zeroIdx,NodeProps entry, [bool collectPredecessors = false]) {
  List<EdgeObj>? results = collectPredecessors ? [] : null;
  g.inEdges(entry.v).forEach((e) {
    var weight =g.edge2<EdgeProps>(e).value;
    var uEntry = g.node(e.v);
    if (results != null) {
      EdgeObj ir = EdgeObj(v:e.v,w: e.w);
      results.add(ir);
    }
    uEntry.out = uEntry.out - weight;
    _assignBucket(buckets, zeroIdx, uEntry);
  });
  g.outEdges(entry.v).forEach((e) {
    var weight = g.edge2<EdgeProps>(e).weight;
    var w = e.w;
    var wEntry = g.node(w);
    wEntry.inner = wEntry.inner - weight;
    _assignBucket(buckets, zeroIdx, wEntry);
  });
  g.removeNode(entry.v);
  return results;
}

_InnerResult2 _buildState(Graph g, num Function(EdgeObj) weightFn) {
  var fasGraph = Graph();
  int maxIn = 0;
  int maxOut = 0;
  for (var v in g.nodes) {
    NodeProps p = NodeProps();
    p.v = v;
    p.inner = 0;
    p.out = 0;
    fasGraph.setNode(v, p);
  }
  // Aggregate weights on nodes, but also sum the weights across multi-edges
  // into a single edge for the fasGraph.
  for (var e in g.edges) {
    var prevWeight =fasGraph.edge<EdgeProps?>(e.v,e.w,e.id)?.value??0;
    num weight = weightFn.call(e);
    var edgeWeight = prevWeight + weight;

    fasGraph.setEdge(e.v, e.w,value:EdgeProps(value: edgeWeight));

    NodeProps p1 = fasGraph.node(e.v);
    p1.out = p1.out + weight;
    maxOut = math.max(maxOut, p1.out).toInt();

    p1 = fasGraph.node(e.w);
    p1.inner = p1.inner + weight;
    maxIn = math.max(maxIn, p1.inner).toInt();
  }

  List<List<NodeProps>> buckets = List.from(range(0, maxOut + maxIn + 3).map((e) {
    return <NodeProps>[];
  }));
  var zeroIdx = maxIn + 1;

  for (var v in fasGraph.nodes) {
    _assignBucket(buckets, zeroIdx, fasGraph.node(v));
  }
  _InnerResult2 result2 = _InnerResult2();
  result2.graph = fasGraph;
  result2.buckets = buckets;
  result2.zeroIdx = zeroIdx;
  return result2;
}

void _assignBucket(List<List<NodeProps>> buckets, int zeroIdx, NodeProps entry) {
  if (entry.outNull==null ) {
    buckets[0].insert(0,entry);
  } else if (entry.innerNull==null) {
    buckets[buckets.length - 1].insert(0,entry);
  } else {
    buckets[(entry.out - entry.inner + zeroIdx).toInt()].insert(0,entry);
  }
}

class _InnerResult2 {
  late Graph graph;
  late List<List<NodeProps>> buckets;
  late int zeroIdx;
}
