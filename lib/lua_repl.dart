import 'dart:async';

import 'package:bonsai/bonsai.dart';
import 'package:lua_dardo/lua.dart';

typedef LuaReplPrintOutput = void Function(String);

class LuaRepl {
  LuaState ls;
  Stream<String> input;
  LuaReplPrintOutput output;
  bool debugLogging;

  LuaRepl(this.ls, this.input, this.output, {this.debugLogging = false});

  Future<void> repl() async {
    await ls.openLibs();
    output('> ');
    await for (String line in input) {
      if (line.isNotEmpty) {
        final ThreadStatus? status;
        final res = await loadLineAsExpression(line);
        if (res) {
          // if load was ok, run the loaded string
          try {
            status = await ls.pCall(0, 0, 0);
            if (status != ThreadStatus.luaOk) {
              print("error calling expression:$status");
            }
            continue;
          } catch (e, st) {
            Log.e("err", e, st);
          }
        } else {
          ls.pop(-1); // get rid of prev loaded line
          try {
            await ls.loadString(line); // now try again without the 'return' prefix
            final result2 = await ls.pCall(0, 0, 0);
            if (result2 != ThreadStatus.luaOk) {
              print("call statement err: $result2");
            }
          } catch (e, st) {
            print("statement exception: $e $st");
          }
        }
      }
      output('> ');
    }
  }

  Future<bool> loadLineAsExpression(String line) async {
    late final ThreadStatus? status;
    bool result = false;
    try {
      status = await ls.loadString("return $line\n");
      if (status != ThreadStatus.luaOk) {
        debugPrint("error with exp: $status");
      } else {
        result = true;
      }
    } catch (e, _) {
      debugPrint("load exception: $e");
    }
    return result;
  }

  void debugPrint(String s) => debugLogging ? output(s) : null;
}
