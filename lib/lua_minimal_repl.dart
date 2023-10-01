import 'dart:async';
import 'dart:isolate';

import 'package:isolate_name_server/isolate_name_server.dart';
import 'package:lua_dardo/lua.dart';
import 'package:server/isolate_worker.dart';
import 'package:server/port_names.dart';

typedef LuaReplPrintOutput = void Function(String);

class LuaMinRepl {
  LuaState ls;
  Stream<String> input;
  LuaReplPrintOutput output;
  bool debugLogging;

  final ReceivePort _rp = ReceivePort();

  LuaMinRepl(this.ls, this.input, this.output, {this.debugLogging = false});

  Future<void> repl() async {
    // register so that any Isolate can talk to us
    IsolateNameServer.registerPortWithName(_rp.sendPort, replPortName);

    await ls.openLibs();

    ls.register('ls', listIsolates);

    await for (String line in input) {
      if (line.isNotEmpty) {
        ls.loadString(line);

        await ls.call(0, 0);

        final luaOutput = ls.checkString(1);
        ls.pop(1);
        if (luaOutput != null) {
          output(luaOutput);
        }
      }
    }
  }

  FutureOr<int> listIsolates(LuaState ls) async {
    print("get list of Isolate IDs from WorkerIsolateManager via port");
    WorkerIsolateManager().request(replPortName, "listIsolates");
    final responseWithIDs = await _rp.first;

    print("got ids:$responseWithIDs");
    ls.pushString(responseWithIDs.toString());
    return 1;
  }
}
