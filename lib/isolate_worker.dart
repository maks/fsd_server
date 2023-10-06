import 'dart:async';
import 'dart:isolate';

import 'package:bonsai/bonsai.dart';
import 'package:isolate_name_server/isolate_name_server.dart';
import 'package:server/port_names.dart';

import 'apollo_worker.dart';

typedef ScriptRequestData = ({String scriptChunk, int pid, String outputPortName, Map<String, dynamic> input});

// FIXME: dont have DI yet, so for now just making it a singleton
class WorkerIsolateManager {
  final Map<String, Isolate> _isolates = {};
  final ReceivePort _rp = ReceivePort();
   
  static final WorkerIsolateManager _singleton = WorkerIsolateManager._internal();

  static int _id = 0;
  static int get idCounter => _id++;

  WorkerIsolateManager._internal() {
    _rp.listen((message) {
      // expect portName of where to send the requested op output
      final [String portName, String op, String id, ...] = message.toString().split(":");
      if (op == "listIsolates") {
        IsolateNameServer.lookupPortByName(portName)?.send(allIsolateIds);
      }
      if (op == "stopIsolate") {
        _stopIsolate(id);
      }
    });

    // register so that any Isolate can talk to us
    IsolateNameServer.registerPortWithName(_rp.sendPort, workerManagerPortName);
  }

  factory WorkerIsolateManager() {
    return _singleton;
  }

  void _addIsolate(Isolate isolate) {
    final id = idCounter;
    _isolates["$id"] = isolate;
    print("add iso:[$id]$isolate");
  }

  void _stopIsolate(String id) {
    final isolate = _isolates[id];
    if (isolate != null) {
      print("stopping isolate:$id");
      isolate.kill(priority: Isolate.immediate);
      _isolates.remove(isolate);
    } else {
      log("isolate to stop not found:$id");
    }
  }

  List<String> get allIsolateIds => _isolates.keys.toList();

  /// helper method to send a request via a SendPort to whichever Isolate the WorkManager is running in
  void request(String replyPortName, String op, String arg) {
    final port = IsolateNameServer.lookupPortByName(workerManagerPortName);
    port?.send("$replyPortName:$op:$arg");
  }
}

Future<void> runApolloIsolateJob(ScriptRequestData d) async {
  final onErrorHandler = ReceivePort();

  onErrorHandler.forEach((mesg) {
    print("[runApolloIsolateJob] isolate [${d.pid}] crashed with $mesg");
    // let the job manager know:
    IsolateNameServer.lookupPortByName(userJobPortName)?.send("${d.pid}:ERROR");
  });

  final isolate = await Isolate.spawn<ScriptRequestData>(
    _apolloIsolateJobFunction,
    d,
    debugName: d.pid.toString(),
    onError: onErrorHandler.sendPort,
  );
  
  WorkerIsolateManager()._addIsolate(isolate);
}

/// ****************************************************************
/// **Entry point** for a newly spawned Isolate running a ApolloVM script
/// ****************************************************************
void _apolloIsolateJobFunction(ScriptRequestData data) async {
  // final output = IsolateNameServer.lookupPortByName(userJobPortName);
  final output = IsolateNameServer.lookupPortByName(data.outputPortName);
  if (output == null) {
    throw Exception("missing user_service Port name");
  }

  // we give the script worker a send function that just immediately sends the data
  // out to the output send port for user jobs to report their "return values"
  await ApolloWorker(
    chunk: data.scriptChunk,
    sendFn: (d) {
      // prefix the sent data with "<pid>:" to identify it to the
      output.send("${data.pid}:$d");
      // print("SENDING=>${data.pid}:$d");
    },
  ).run(data.input);
}
