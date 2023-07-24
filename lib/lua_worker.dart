import 'dart:io';

import 'package:lua_dardo/lua.dart';
import 'package:tribbles/tribbles.dart';

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

    ls.pushDartFunction(wait);
    ls.setGlobal('wait');

    ls.pushString(Tribble.currentId);
    ls.setGlobal('tid');
  }

  void run(String message) {
    ls.pushString(message);
    // Set variable name
    ls.setGlobal("mesg");

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

  /// function exposed to Lua: **SYNCHRONOUS** wait
  /// This will block execution of Lua AND the hosting Dart Isolate
  /// for the given number of seconds
  int wait(LuaState ls) {
    final seconds = ls.checkInteger(-1);
    ls.pop(-1);
    if (seconds != null) {
      sleep(Duration(seconds: seconds));
    } else {
      throw Exception("invalid seconds to wait:$seconds");
    }
    return 1;
  }
}
