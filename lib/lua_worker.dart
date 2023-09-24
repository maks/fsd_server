// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:isolate';

import 'package:lua_dardo/lua.dart';

typedef SendToDart = void Function(dynamic s);

class LuaWorker {
  late final LuaState ls;
  final SendToDart sendFn;
  final String chunk;
  final _ready = Completer<void>();

  LuaWorker({required this.chunk, required this.sendFn}) {
    ls = LuaState.newState();

    ls.openLibs().then((value) {
      ls.register('send', lua_sendString);

      ls.register('sleep', lua_sleep);

      ls.register('dprint', lua_print);

      ls.pushString(Isolate.current.debugName);
      ls.setGlobal('tid');

      _ready.complete();
    }); // allow all std Lua libs
  }

  Future<void> run(Map<String, dynamic> data) async {
    await _ready.future;

    for (final d in data.keys) {
      final val = data[d];
      if (val is String) {
        ls.pushString(d);
      } else if (val is int) {
        ls.pushInteger(val);
      } else if (val is bool) {
        ls.pushBoolean(val);
      }
      // Set variable name
      ls.setGlobal(d);
    }

    ls.loadString(chunk);

    await ls.call(0, 0);
  }

  // ======= Functions exposed to Lua ====================================

  /// Function exposed to Lua: allows Lua to send strings to Dart host
  /// which will cause this worker to call the `sendFn` callback function
  /// with the String passed from Lua
  int lua_sendString(LuaState ls) {
    final reply = ls.checkString(-1);
    ls.pop(-1);
    if (reply != null) {
      sendFn(reply);
    }
    return 1;
  }

  /// Function exposed to Lua: allows Lua to pause for given time but using hosts
  /// async so as not to block the underlying host thread
  FutureOr<int> lua_sleep(LuaState ls) async {
    // print("start Dart Sleep for Lua");
    final delayInMs = ls.checkInteger(1);
    ls.pop(1);
    await Future<void>.delayed(Duration(milliseconds: delayInMs ?? 1));
    // print("end Dart Sleep for Lua");
    return 1;
  }

  /// Function exposed to Lua: allows Lua to print to std output
  int lua_print(LuaState ls) {
    final val = ls.checkString(1);
    ls.pop(1);

    print("[lua] $val");
    return 1;
  }
}
