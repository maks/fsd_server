import 'dart:io';
import 'dart:isolate';

import 'package:bonsai/bonsai.dart';
import 'package:isolate_name_server/isolate_name_server.dart';

import 'isolate_worker.dart';

class LoadMaker {
  int _completionCount = 0;
  int _workerCount = 0;

  int get workerCount => _workerCount;

  LoadMaker();

  int getAndClearCompletionCount() {
    final res = _completionCount;
    _completionCount = 0;
    return res;
  }

  Future<void> startWorkLoad(int workerCount) async {
    _workerCount += workerCount;

    // the port that load workers will report back on
    ReceivePort rp = ReceivePort();
    rp.listen((message) {
      if (message.toString().startsWith("completed:")) {
        _completionCount++;
      }
    });
    // register port so that worker isolates can look it up when they need to report their completion result
    IsolateNameServer.registerPortWithName(rp.sendPort, "loadmaker");

    final script = File("scripts/load_maker.lua").readAsStringSync();
    for (int i = 0; i < workerCount; i++) {
      // pure Dart load using Isolate directly not Tribbles
      await createLuaIsolateLoad(script);
    }
    log("started $_workerCount load workers");
  }
}

