import 'dart:async';
import 'dart:isolate';

import 'package:bonsai/bonsai.dart';
import 'package:isolate_name_server/isolate_name_server.dart';
import 'package:server/port_names.dart';

import 'lua_worker.dart';

typedef LuaRequestData = ({String luaChunk, int id, String outputPortName, Map<String, dynamic> input});

class WorkerManager {
  final List<Isolate> isolates = [];

  static final WorkerManager _singleton = WorkerManager._internal();

  factory WorkerManager() {
    return _singleton;
  }

  WorkerManager._internal();
}

Future<void> runLuaIsolateJob(LuaRequestData d, String id) async {
  final onErrorHandler = ReceivePort();

  onErrorHandler.forEach((mesg) {
    Log.e("[runLuaIsolateJob] isolate [${d.id}] crashed with $mesg");
    // let the job manager know:
    IsolateNameServer.lookupPortByName(userJobPortName)?.send("${d.id}:ERROR");
  });

  await Isolate.spawn<LuaRequestData>(
    _luaIsolateJobFunction,
    d,
    debugName: id,
    onError: onErrorHandler.sendPort,
  );
}


/// **Entry point** for a newly spawned Isolate running a Lua script
void _luaIsolateJobFunction(LuaRequestData data) async {
  // final output = IsolateNameServer.lookupPortByName(userJobPortName);
  final output = IsolateNameServer.lookupPortByName(data.outputPortName);
  if (output == null) {
    throw Exception("missing user_service Port name");
  }
  
  // print("start Lua [${data.id}] (${data.input})");

  // we give the Lua worker a send function that just immediately sends the data
  // out to the output send port for user jobs to report their "return values"
  await LuaWorker(
    chunk: data.luaChunk,
    sendFn: (d) {
      // prefix the sent data with "<request_id>:" to identify it to the
      output.send("${data.id}:$d");
      // print("SENDING=>${data.id}:$d");
    },
  ).run(data.input);
}
