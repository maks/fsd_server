import 'package:apollovm/apollovm.dart';

typedef SendToDart = void Function(dynamic s);

class ApolloWorker {
  final vm = ApolloVM();
  final SendToDart sendFn;
  final _ready = Completer<void>();
  late final ApolloRunner dartRunner;

  ApolloWorker({required String chunk, required this.sendFn}) {
    final codeUnit = SourceCodeUnit('dart', chunk, id: 'test');
    vm.loadCodeUnit(codeUnit).then((loadOK) {
      if (!loadOK) {
        print("Can't load source!");
        return;
      }
      dartRunner = vm.createRunner('dart')!;

      // ======= Functions exposed to ApolloVM ====================================
      // map the `print` function in the VM:
      dartRunner.externalPrintFunction = (o) => print("» $o");
      // map a async functions to VM
      dartRunner.externalFunctionMapper
          ?.mapExternalFunction1(ASTTypeVoid.instance, 'sleep', ASTTypeObject.instance, 'o', (o) => _sleep(o as int));
      dartRunner.externalFunctionMapper
          ?.mapExternalFunction1(ASTTypeVoid.instance, 'send', ASTTypeObject.instance, 'o', (o) => sendFn(o as String));    

      _ready.complete();
    });
  }

  Future<void> run(Map<String, dynamic> data) async {
    await _ready.future; // wait for async init in constructor to complete

    var astValue = await dartRunner.executeClassMethod(
      '',
      'Calc',
      data["fn_name"] as String,
      positionalParameters: [
        [data["sum_to"]]
      ],
    );
    final result = astValue.getValueNoContext();
    if (result != null) {
      sendFn("$result");
    }
  }

  // int get luaOpsCount => ls.opsCount;

  void _sleep(int ms) async {
    await Future<void>.delayed(Duration(milliseconds: ms));
  }
}
