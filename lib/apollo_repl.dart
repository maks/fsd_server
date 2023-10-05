import 'dart:math';

import 'package:apollovm/apollovm.dart';

typedef LuaReplPrintOutput = void Function(String);

class ApolloVMRepl {
  final vm = ApolloVM();

  Stream<String> input;
  LuaReplPrintOutput output;
  bool debugLogging;
  bool showPrompt;

  late final ApolloRunner? dartRunner = vm.createRunner('dart');

  ApolloVMRepl(this.input, this.output, {this.debugLogging = false, this.showPrompt = true});

  Future<void> repl() async {
    if (showPrompt) {
      output('> ');
    }
    await for (String? line in input) {
      if (line?.isNotEmpty == true) {
        final fnName = "_a${Random().nextInt(100000)}";
        final prefix = "void $fnName() { ";
        const suffix = "}";

        line = "$prefix $line $suffix";
        // eval line
        if (debugLogging) {
          print("LINE:|$line|");
        }
        final codeUnit = SourceCodeUnit('dart', line, id: 'repl');
        try {
          await vm.loadCodeUnit(codeUnit);
        } catch (e, st) {
          output("error loading code:$line");
          if (debugLogging) {
            print("error loading code:$e $st");
          }
          continue;
        }
        if (dartRunner == null) {
          throw Exception("invalid runner state");
        }
        final runner = dartRunner!;

        // ======= Functions exposed to ApolloVM ====================================
        // map the `print` function in the VM:
        runner.externalPrintFunction = (o) => print("» $o");
        // map a async functions to VM
        runner.externalFunctionMapper
            ?.mapExternalFunction1(ASTTypeVoid.instance, 'sleep', ASTTypeObject.instance, 'o', (o) => _sleep(o as int));
        runner.externalFunctionMapper?.mapExternalFunction1(
            ASTTypeVoid.instance, 'show', ASTTypeObject.instance, 'o', (o) => output(o as String));

        var astValue = await runner.tryExecuteFunction(
          '',
          fnName,
        );
        final result = astValue?.getValueNoContext();
        if (result != null) {
          output("$result");
        }
      } else if (line == null) {
        return;
      }
      if (showPrompt) {
        output('> ');
      }
    }
  }

  void _sleep(int ms) async {
    await Future<void>.delayed(Duration(milliseconds: ms));
  }

  void debugPrint(String s) => debugLogging ? output(s) : null;

  // Future<bool> loadLineAsExpression(String line) async {
  //   late final ThreadStatus? status;
  //   bool result = false;
  //   try {
  //     status = await ls.loadString("return $line\n");
  //     if (status != ThreadStatus.luaOk) {
  //       debugPrint("error with exp: $status");
  //     } else {
  //       result = true;
  //     }
  //   } catch (e, _) {
  //     debugPrint("load exception: $e");
  //   }
  //   return result;
  // }
}
