import 'dart:async';
import 'dart:isolate';

import 'package:bonsai/bonsai.dart';
import 'package:isolate_name_server/isolate_name_server.dart';
import 'package:server/load_maker.dart';

import 'lua_worker.dart';
import 'names.dart';

typedef LuaRequestData = ({String luaChunk, int id, Map<String, dynamic> input});

Future<void> runLuaLoadWorker(LuaRequestData d, String id) async {
  await Isolate.spawn<LuaRequestData>(luaIsolateLoadWorkerFunction, d, debugName: id);
}

Future<void> runLuaIsolateJob(LuaRequestData d, String id) async {
  final onErrorHandler = ReceivePort();

  onErrorHandler.forEach((mesg) {
    Log.e("[runLuaIsolateJob] isolate [${d.id}] crashed with $mesg");
    // let the job manager know:
    IsolateNameServer.lookupPortByName(userJobPortName)?.send("${d.id}:ERROR");
  });

  await Isolate.spawn<LuaRequestData>(
    luaIsolateJobFunction,
    d,
    debugName: id,
    onError: onErrorHandler.sendPort,
  );
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
    int i = 1;
    for (;;) {
      accum = accum + i++;
      if (i > 10000) {
        i = 0;
        final message = "completed:$id[$accum]";
        ins.send(message);
        await Future<void>.delayed(Duration(milliseconds: 1));
      }
    }
  }
}

void luaIsolateLoadWorkerFunction(LuaRequestData data) async {
  final output = IsolateNameServer.lookupPortByName(LoadMaker.portName);
  if (output == null) {
    throw Exception("missing user_service Port name");
  }
  // we give the Lua worker a send function that just immediately sends the data
  // out to the output send port for user jobs to report their "return values"
  await LuaWorker(
    chunk: data.luaChunk,
    sendFn: (d) {
      output.send("completed:$d");
    },
  ).run(data.input);
}

void luaIsolateJobFunction(LuaRequestData data) async {
  final output = IsolateNameServer.lookupPortByName(userJobPortName);
  if (output == null) {
    throw Exception("missing user_service Port name");
  }
  print("start Lua [${data.id}] (${data.input})");

  // we give the Lua worker a send function that just immediately sends the data
  // out to the output send port for user jobs to report their "return values"
  await LuaWorker(
    chunk: data.luaChunk,
    sendFn: (d) {
      // prefix the sent data with "<request_id>:" to identify it to the
      print("SENDING=>${data.id}:$d");
      output.send("${data.id}:$d");
    },
  ).run(data.input);
}

class LuaSingleIsolateExecutor {
  int createdCount = 0;
  final List<LuaRequestData> _requestQueue = [];
  late final SendPort output;

  LuaSingleIsolateExecutor() {
    final o = IsolateNameServer.lookupPortByName(LoadMaker.portName);
    if (o == null) {
      throw Exception("missing user_service Port name");
    } else {
      output = o;
    }

    Timer.periodic(Duration(milliseconds: 1), (timer) {
      _dispatch();
    });
  }

  void _dispatch() async {
    final data = _requestQueue.firstOrNull;
    if (data == null) {
      return;
    }
    print("running Lua Executor jobs");
    // we give the Lua worker a send function that just immediately sends the data
    // out to the output send port for user jobs to report their "return values"
    output.send("created");
    createdCount++;
    LuaWorker(
      chunk: data.luaChunk,
      sendFn: (d) {
        // prefix the sent data with "<request_id>:" to identify it to the
        output.send("$createdCount:$d");
      },
    ).run(data.input);
  }

  void exec(LuaRequestData data) {
    _requestQueue.add(data);
  }
}
