import 'dart:isolate';

import 'package:apollovm/apollovm.dart';
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
    final pid = isolate.debugName ?? "$idCounter";
    _isolates[pid] = isolate;
  }

  void _removeIsolate(String id) {
    _isolates.remove(id);
    print("removed finished isolate: $id");
  }

  void _stopIsolate(String id) {
    final isolate = _isolates[id];
    if (isolate != null) {
      print("stopping isolate:$id");
      isolate.kill(priority: Isolate.beforeNextEvent);
      _isolates.remove(id);
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
  final onExitHandler = ReceivePort();

  onErrorHandler.forEach((mesg) {
    print("[runApolloIsolateJob] isolate [${Isolate.current.debugName}] crashed with: $mesg");
    // let the job manager know:
    IsolateNameServer.lookupPortByName(userJobPortName)?.send("${d.pid}:ERROR");
  });

  onExitHandler.forEach((mesg) {
    final pid = mesg as String?;
    print("[runApolloIsolateJob] isolate [$pid] finished");
    // remove from isolates list
    if (pid != null) {
      WorkerIsolateManager()._removeIsolate(pid);
      IsolateNameServer.lookupPortByName(userJobPortName)?.send("${d.pid}:ERROR");
    }
  });
  
  final pid = WorkerIsolateManager.idCounter;
  final isolate = await Isolate.spawn<ScriptRequestData>(
    _apolloIsolateJobFunction,
    d,
    debugName: "$pid",
    onError: onErrorHandler.sendPort,
    errorsAreFatal: true,
    paused: true,
  );
  isolate.addOnExitListener(onExitHandler.sendPort, response: "$pid");  
  WorkerIsolateManager()._addIsolate(isolate);
  isolate.resume(isolate.pauseCapability!);
}

/// ****************************************************************
/// **Entry point** for a newly spawned Isolate running a ApolloVM script
/// ****************************************************************
void _apolloIsolateJobFunction(ScriptRequestData data) async {
  final output = IsolateNameServer.lookupPortByName(data.outputPortName);
  if (output == null) {
    throw Exception("missing user_service Port name");
  }

  // we give the script worker a send function that just immediately sends the data
  // out to the output send port for user jobs to report their "return values"
  final worker = ApolloWorker(
    chunk: data.scriptChunk,
    sendFn: (d) {
      // prefix the sent data with "<pid>:" to identify it to the
      output.send("${data.pid}:$d");
    },
  );

  final rp = ReceivePort();
  IsolateNameServer.registerPortWithName(rp.sendPort, "${data.pid}");

  rp.listen((message) {
    final mesg = "[${data.pid}] OPCOUNT:${VMContext.opCount}";
    final output = IsolateNameServer.lookupPortByName(replWSOUTPortName);
    output?.send(mesg);
  });

  await worker.run(data.input);
}
