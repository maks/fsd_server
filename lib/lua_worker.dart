import 'dart:isolate';

import 'package:lua_dardo/lua.dart';

typedef SendToDart = void Function(dynamic s);

class LuaWorker {
  late final LuaState ls;
  final SendToDart sendFn;
  final String chunk;
  final Map<String, dynamic> data; 

  LuaWorker({required this.chunk, required this.sendFn, required this.data}) {
    ls = LuaState.newState();

    ls.openLibs(); // allow all std Lua libs
    ls.pushDartFunction(sendString);
    ls.setGlobal('send');

    ls.pushString(Isolate.current.debugName);
    ls.setGlobal('tid');
  }

  void run() async {
    for (final d in data.keys) {
      final val = data[d];
      if (val is String) {
        ls.pushString(d);
      } else if (val is int) {
        print("lua push int:$d->${data[d]}");
        ls.pushInteger(val);
      } else if (val is bool) {
        ls.pushBoolean(val);
      }
      // Set variable name
      ls.setGlobal(d);
    }
   
    ls.loadString(chunk);

    ls.call(0, 0);
  }

  /// Function exposed to Lua: allows Lua to send strings to Dart host
  /// which will cause this worker to call the `sendFn` callback function
  /// with the String passed from Lua
  int sendString(LuaState ls) {
    final reply = ls.checkString(-1);
    ls.pop(-1);
    if (reply != null) {
      sendFn(reply);
    }
    return 1;
  }
}
