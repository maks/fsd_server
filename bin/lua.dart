import 'dart:convert';
import 'dart:io';

import 'package:lua_dardo/lua.dart';
import 'package:server/lua_repl.dart';

void main(List<String> args) async {
  LuaState state = LuaState.newState();
  // allow using all lua std libraries
  await state.openLibs();

  stdout.write('LuaDardo 0.0.4 (Lua 5.3) Ctrl-d to exit\n');

  final Stream<String> input = stdin.transform(utf8.decoder).transform(const LineSplitter());

  LuaRepl(state, input, (String s) => stdout.write(s), debugLogging: true).repl(); 
}


