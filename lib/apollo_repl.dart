import 'dart:isolate';
import 'dart:math';

import 'package:apollovm/apollovm.dart';
import 'package:isolate_name_server/isolate_name_server.dart';

import 'isolate_worker.dart';
import 'port_names.dart';

typedef LuaReplPrintOutput = void Function(String);

class ApolloVMRepl {
  final vm = ApolloVM();

  Stream<String> input;
  LuaReplPrintOutput output;
  bool debugLogging;
  bool showPrompt;

  final _recvPort = ReceivePort();
  late final Stream<dynamic> _mailbox = _recvPort.asBroadcastStream();

  late final ApolloRunner? dartRunner = vm.createRunner('dart');

  ApolloVMRepl(this.input, this.output, {this.debugLogging = false, this.showPrompt = true}) {
    IsolateNameServer.registerPortWithName(_recvPort.sendPort, replPortName);
  }

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
        // map functions to VM
        runner.externalFunctionMapper
            ?.mapExternalFunction1(ASTTypeVoid.instance, 'sleep', ASTTypeObject.instance, 'o', (o) => _sleep(o as int));
        runner.externalFunctionMapper?.mapExternalFunction1(
            ASTTypeVoid.instance, 'show', ASTTypeObject.instance, 'o', (o) => _safeOutput(o));
        runner.externalFunctionMapper?.mapExternalFunction0(ASTTypeArray.instanceOfString, 'ps', () => _isoList());    
        runner.externalFunctionMapper?.mapExternalFunction1(
            ASTTypeVoid.instance, 'stop', ASTTypeObject.instance, 'o', (o) => _stopIsolate(o as String));
        runner.externalFunctionMapper?.mapExternalFunction1(
            ASTTypeVoid.instance, 'psload', ASTTypeObject.instance, 'o', (o) => _psByLoad(o as int));
        

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

  void _safeOutput(dynamic o) => output("$o");
  
  Future<List<String>> _isoList() async {
    List<String> psList = [];
    WorkerIsolateManager().request(replPortName, "listIsolates", "");
    final mesg = await _mailbox.first;
    if (mesg is List<String>) {
      psList = mesg;
    }
    return psList;
  }

  void _stopIsolate(String id) {
    WorkerIsolateManager().request(replPortName, "stopIsolate", id);
  }

  void _psByLoad(int count) {
    for (int pid = 0; pid < count; pid++) {
      final workerPort = IsolateNameServer.lookupPortByName("$pid");
      if (workerPort == null) {
        output("missing user_service Port name");
      } else {
        workerPort.send("getOpsCount");
      }
    }
  }
}
