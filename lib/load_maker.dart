import 'dart:io';
import 'dart:isolate';

import 'package:bonsai/bonsai.dart';
import 'package:isolate_name_server/isolate_name_server.dart';

import 'isolate_worker.dart';

class LoadMaker {
  static const portName = "load_maker"; 

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
    // the port that load workers will report back on
    ReceivePort rp = ReceivePort();
    rp.listen((message) {
      if (message.toString().startsWith("completed:")) {
        _completionCount++;
      }
    });
    // register port so that worker isolates can look it up when they need to report their completion result
    IsolateNameServer.registerPortWithName(rp.sendPort, portName);

    final script = File("scripts/load_maker.lua").readAsStringSync();
    
    for (int i = 0; i < workerCount; i++) {
      final LuaRequestData data = (id: i, luaChunk: script);
      await runLuaIsolateJob(data, "$i");
      // await Future.delayed(Duration(milliseconds: 2));
      _workerCount++;
    }
    log("started $_workerCount load workers");
  }
}

