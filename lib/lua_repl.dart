import 'package:lua_dardo/lua.dart';

/// Function called to supply each user input line in the "read" part of the Lua REPL
typedef LuaReplReadInput = String? Function();

typedef LuaReplPrintOutput = void Function(String);

class LuaRepl {
  LuaState ls;
  LuaReplReadInput readInput;
  LuaReplPrintOutput output;
  bool debugLogging;

  LuaRepl(this.ls, this.readInput, this.output, {this.debugLogging = false});

  void repl() {
    while (true) {
      output('> ');
      final input = readInput();
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

  void debugPrint(String s) => debugLogging ? output(s) : null;
}
