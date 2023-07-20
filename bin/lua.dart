import 'dart:io';

import 'package:lua_dardo/lua.dart';
import 'package:server/lua_repl.dart';

void main(List<String> args) {
  LuaState state = LuaState.newState();
  // allow using all lua std libraries
  state.openLibs();

  stdout.write('LuaDardo 0.0.4 (Lua 5.3) Ctrl-d to exit\n');

  LuaRepl(state, () => stdin.readLineSync(), (String s) => stdout.write(s), debugLogging: false).repl(); 
}


