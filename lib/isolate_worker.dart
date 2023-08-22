import 'dart:isolate';

import 'package:isolate_name_server/isolate_name_server.dart';
import 'package:server/load_maker.dart';


import 'lua_worker.dart';
import 'names.dart';

typedef LuaRequestData = ({String luaChunk, int id, int input});

Future<void> createLuaIsolateLoad(String luaChunk) async {
  await Isolate.spawn<String>(luaIsolateWorkerFunction, luaChunk);
}

Future<void> runLuaIsolateJob(LuaRequestData d) async {
  await Isolate.spawn<LuaRequestData>(luaIsolateJobFunction, d);
}

void dartIsolateWorkerFunction(String data) async {
  final ins = IsolateNameServer.lookupPortByName(LoadMaker.portName);
  if (ins != null) {
  } else {
    throw Exception("missing load_maker Port name");
  }
  final id = Isolate.current.debugName;

  while (true) {
    // some basic fake load
    int accum = 0;
    for (int i = 0; i < 50000; i++) {
      accum = accum + i;
    }
    final message = "completed:$id[$accum]";
    ins.send(message);
    await Future<void>.delayed(Duration(seconds: 1));
  }
}

void luaIsolateWorkerFunction(String luaChunk) async {
  final ins = IsolateNameServer.lookupPortByName(LoadMaker.portName);
  if (ins != null) {
  } else {
    throw Exception("missing user_service Port name");
  }
  while (true) {
    // we give the Lua worker a send function that just immediately sends the data
    // out to the port we are given
    LuaWorker(
      chunk: luaChunk,
      sendFn: (d) {
        final message = "completed:todo[$d]";
        ins.send(message);
      },
      data: {},
    ).run();

    await Future<void>.delayed(Duration(seconds: 1));
  }
}

void luaIsolateJobFunction(LuaRequestData data) async {
  final output = IsolateNameServer.lookupPortByName(userJobPortName);
  if (output == null) {
    throw Exception("missing user_service Port name");
  }

  // we give the Lua worker a send function that just immediately sends the data
  // out to the output send port for user jobs to report their "return values"
  LuaWorker(
    chunk: data.luaChunk,
    sendFn: (d) {
      // prefix the sent data with "<request_id>:" to identify it to the
      output.send("${data.id}:$d");
    },
    data: {"input": data.input},
  ).run();
}
