import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:isolate_name_server/isolate_name_server.dart';
import 'package:server/isolate_worker.dart';
import 'package:server/lua_worker.dart';
import 'package:server/port_names.dart';

int _reponsesPerSec = 0;

void main(List<String> args) async {
  print("Starting");

  ReceivePort rp = ReceivePort();
  // register port so that job isolates can look it up when they need to report their completion result
  IsolateNameServer.registerPortWithName(rp.sendPort, userJobPortName);

  final List<SendPort> isoPortsList = [];

  final chunk = await File("scripts/infinite.lua").readAsString();

  final count = int.parse(args[0]);
  final jobs = int.parse(args[1]);

  rp.listen((message) async {
    if (message is SendPort) {
      isoPortsList.add(message);
    } else {
      _reponsesPerSec++;
      print("mesg:$message");
    }
  });

  for (int i = 0; i < jobs; i++) {
    final LuaRequestData data = (pid: i, luaChunk: chunk, input: {}, outputPortName: "NA");
    await Isolate.spawn<LuaRequestData>(luaIsolateJob, data, debugName: "$i");
  }

  Timer.periodic(Duration(seconds: 1), (timer) {
    print("[${timer.tick}]response rate:$_reponsesPerSec");
    _reponsesPerSec = 0;
  });

  await Future<void>.delayed(Duration(seconds: 1));

  print("init send ${isoPortsList.length}");
 
  for (final i in isoPortsList) {
    i.send(count);
  }
  
}

void luaIsolateJob(LuaRequestData data) async {
  final output = IsolateNameServer.lookupPortByName(userJobPortName);
  if (output == null) {
    throw Exception("missing user_service Port name");
  }

  final mailbox = ReceivePort();
  output.send(mailbox.sendPort);

  mailbox.listen(
    (message) async {
      final input = (message is Map<String, dynamic>) ? message : <String, dynamic>{};
      LuaWorker(
        chunk: data.luaChunk,
        sendFn: (d) {
          // prefix the sent data with "<request_id>:" to identify it to the
          output.send("${data.pid}:$d");
        },
      ).run(input);
    },
  );
}
