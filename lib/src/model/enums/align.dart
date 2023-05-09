import 'package:flutter/widgets.dart';

enum GraphAlign{
  //up to Left
  utl,
  // up to Right
  utr,
  // down to Left
  dtl,
  // down to Right
  dtr,
}

GraphAlign fromStr(String s){
  s=s.toLowerCase();
  if(s=='utl'){
    return GraphAlign.utl;
  }
  if(s=='utr'){
    return GraphAlign.utr;
  }
  if(s=='dtl'){
    return GraphAlign.dtl;
  }
  if(s=='dtr'){
    return GraphAlign.dtr;
  }
  throw FlutterError('违法参数');
}