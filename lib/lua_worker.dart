import 'package:lua_dardo/lua.dart';

typedef SendToDart = void Function(dynamic s);

class LuaWorker {
  late final LuaState ls;
  final SendToDart sendFn;
  final String chunk;

  LuaWorker({required this.chunk, required this.sendFn}) {
    ls = LuaState.newState();

    ls.openLibs(); // allow all std Lua libs
    ls.pushDartFunction(sendString);
    ls.setGlobal('send');
  }

  void run(String message) {
    ls.pushString(message);
    // Set variable name
    ls.setGlobal("mesg");

    ls.loadString(chunk);

    ls.call(0, 0);
  }

  int sendString(LuaState ls) {
    final reply = ls.checkString(-1);
    ls.pop(-1);
    if (reply != null) {
      sendFn(reply);
    }
    return 1;
  }
}
