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

  void run(String request) {
    ls.pushString(request);
    // Set variable name
    ls.setGlobal("req");

    ls.loadString(chunk);

    ls.call(0, 0);
  }

  int sendString(LuaState ls) {
    final mesg = ls.checkString(-1);
    ls.pop(-1);
    if (mesg != null) {
      sendFn(mesg);
    }
    return 1;
  }
}
