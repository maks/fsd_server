import 'dart:io';
import 'dart:isolate';

import 'package:bonsai/bonsai.dart';
import 'package:isolate_name_server/isolate_name_server.dart';

import 'isolate_worker.dart';

class LoadMaker {
  int _completionCount = 0;

  LoadMaker();

  int getAndClearCompletionCount() {
    final res = _completionCount;
    _completionCount = 0;
    return res;
  }

  Future<void> startWorkLoad(int workerCount) async {
    ReceivePort rp = ReceivePort();
    rp.listen((message) {
      if (message.toString().startsWith("completed:")) {
        _completionCount++;
        // and just keep looping repeatedly running the worker load script
      }
    });
    IsolateNameServer.registerPortWithName(rp.sendPort, "loadmaker");

    final script = File("scripts/load_maker.lua").readAsStringSync();
    for (int i = 0; i < workerCount; i++) {
      // pure dart load using Isolate directly not Tribbles
      await createLuatIsolateLoad(script);
    }
    log("started $workerCount load workers");
  }
}

