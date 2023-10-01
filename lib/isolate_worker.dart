import 'dart:async';
import 'dart:isolate';

import 'package:bonsai/bonsai.dart';
import 'package:collection/collection.dart';
import 'package:isolate_name_server/isolate_name_server.dart';
import 'package:server/port_names.dart';

import 'lua_worker.dart';

typedef LuaRequestData = ({String luaChunk, int pid, String outputPortName, Map<String, dynamic> input});

// FIXME: dont have DI yet, so for now just making it a singleton
class WorkerIsolateManager {
  final List<Isolate> _isolates = [];
  final ReceivePort _rp = ReceivePort();
   
  static final WorkerIsolateManager _singleton = WorkerIsolateManager._internal();

  WorkerIsolateManager._internal() {
    _rp.listen((message) {
      // expect portName of where to send the requested op output
      final [String portName, String op, ...] = message.toString().split(":");
      // if (portName == null || op == null) {
      //   Log.e("invalid message: $message");
      // } else {
      if (op == "listIsolates") {
        IsolateNameServer.lookupPortByName(portName)?.send(allIsolateIds);
      }
      // }
    });

    // register so that any Isolate can talk to us
    IsolateNameServer.registerPortWithName(_rp.sendPort, workerManagerPortName);
  }

  factory WorkerIsolateManager() {
    return _singleton;
  }

  void addIsolate(Isolate isolate) {
    _isolates.add(isolate);
    print("added Isolate:$allIsolateIds");
  }

  void stopIsolate(String id) {
    final isolate = _isolates.firstWhereOrNull((element) => element.debugName == id);
    if (isolate != null) {
      isolate.kill(priority: Isolate.immediate);
      _isolates.remove(isolate);
    }
  }

  List<String> get allIsolateIds {
    print("curr iso:${Isolate.current.debugName}");
    return _isolates.map((e) => e.debugName ?? '-1').toList();
  }

  void request(String replPortName, String op) {
    final port = IsolateNameServer.lookupPortByName(workerManagerPortName);
    port?.send("$replPortName:$op");
  }
}

Future<void> runLuaIsolateJob(LuaRequestData d) async {
  final onErrorHandler = ReceivePort();

  onErrorHandler.forEach((mesg) {
    Log.e("[runLuaIsolateJob] isolate [${d.pid}] crashed with $mesg");
    // let the job manager know:
    IsolateNameServer.lookupPortByName(userJobPortName)?.send("${d.pid}:ERROR");
  });

  final isolate = await Isolate.spawn<LuaRequestData>(
    _luaIsolateJobFunction,
    d,
    debugName: d.pid.toString(),
    onError: onErrorHandler.sendPort,
  );
  WorkerIsolateManager().addIsolate(isolate);
}

/// ****************************************************************
/// **Entry point** for a newly spawned Isolate running a Lua script
/// ****************************************************************
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
      // prefix the sent data with "<pid>:" to identify it to the
      output.send("${data.pid}:$d");
      // print("SENDING=>${data.id}:$d");
    },
  ).run(data.input);
}
