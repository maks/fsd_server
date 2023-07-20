import 'dart:io';

import 'package:lua_dardo/lua.dart';

const _debugLogging = false;

void main(List<String> args) {
  LuaState state = LuaState.newState();
  // allow using all lua std libraries
  state.openLibs();

  stdout.write('LuaDardo 0.0.4 (Lua 5.3) Ctrl-d to exit\n');

  repl(state);
}

void repl(LuaState ls) {
  while (true) {
    stdout.write('> ');
    final input = stdin.readLineSync();
    if (input != null) {
      late final ThreadStatus? status;
      final res = loadLineAsExpression(ls, input);
      if (res) {
        // if load was ok, run the loaded string
        try {
          status = ls.pCall(0, 0, 1);
          if (status != ThreadStatus.lua_ok) {
            print("error calling expression: status");
          }
          continue;
        } catch (e, _) {
          print(e);
        }
      } else {
        ls.pop(-1); // get rid of prev loaded line
        try {
          ls.loadString(input); // now try again without the 'return' prefix
          final result2 = ls.pCall(0, 0, 0);
          if (result2 != ThreadStatus.lua_ok) {
            print("call statement err: $result2");
          }
        } catch (e, _) {
          print("statement exception: $e");
        }
      }
    } else {
      break;
    }
  }
}

bool loadLineAsExpression(LuaState ls, String line) {
  late final ThreadStatus? status;
  bool result = false;
  try {
    status = ls.loadString("return $line\n");
    if (status != ThreadStatus.lua_ok) {
      debugPrint("error with exp: $status");
    } else {
      result = true;
    }
  } catch (e, _) {
    debugPrint("load exception: $e");
  }
  return result;
}

void debugPrint(String s) => _debugLogging ? print(s) : null;
