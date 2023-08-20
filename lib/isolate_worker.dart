import 'dart:isolate';

import 'package:isolate_name_server/isolate_name_server.dart';

import 'lua_worker.dart';

Future<void> createDartIsolateLoad() async {
  await Isolate.spawn<String>(dartIsolateWorkerFunction, "");
}

Future<void> createLuaIsolateLoad(String luaChunk) async {
  await Isolate.spawn<String>(dartIsolateWorkerFunction, luaChunk);
}

void dartIsolateWorkerFunction(String data) async {
  final ins = IsolateNameServer.lookupPortByName("loadmaker");
  if (ins != null) {
  } else {
    throw Exception("missing loadmaker Port name");
  }
  final id = Isolate.current.debugName;
  
  while (true) {
    int accum = 0;
    for (int i = 0; i < 500; i++) {
      accum = accum + i;
    } 
    final message = "completed:$id[$accum]";
    ins.send(message);
    await Future<void>.delayed(Duration(seconds: 1));
  }
}

void luaIsolateWorkerFunction(String data) async {
  final ins = IsolateNameServer.lookupPortByName("loadmaker");
  if (ins != null) {
  } else {
    throw Exception("missing loadmaker Port name");
  }
  while (true) {
    // we give the Lua worker a send function that just immediately sends the data
    // out to the messages stream of this Tribble
    LuaWorker(
      chunk: data,
      sendFn: (d) {
        final message = "completed:todo[$d]";
        ins.send(message);
      },
      data: {},
    ).run("");

    await Future<void>.delayed(Duration(seconds: 1));
  }
}
