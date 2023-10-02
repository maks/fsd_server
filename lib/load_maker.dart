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
      final result = message.toString().split(":");
      // HARDCODED: result must be the magic number: sum(50) == 1275
      if (result.length == 2 && result[1] == "1275") { 
        _completionCount++;
      }
    });
    // register port so that worker isolates can look it up when they need to report their completion result
    IsolateNameServer.registerPortWithName(rp.sendPort, portName);

    // final script = File("scripts/load_maker.lua").readAsStringSync();
    final script = File("scripts/calc.dart").readAsStringSync();
    
    for (int i = 0; i < workerCount; i++) {
      final LuaRequestData data = (
        pid: i,
        luaChunk: script,
        outputPortName: LoadMaker.portName,
        input: {"sum_to": 50, "fn_name": "loop"},
      );
      // await runLuaIsolateJob(data);
      await runApolloIsolateJob(data);
      _workerCount++;
      if (_workerCount % 500 == 0) {
        await Future<void>.delayed(Duration(milliseconds: 10));
      }      
    }
    log("started $_workerCount load workers");
  }
}

