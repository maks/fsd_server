import 'dart:io';

import 'package:apollovm/apollovm.dart';

void main(List<dynamic> args) async {
  final vm = ApolloVM();
  final script = args[0] as String;
  print("src:$script");
  final source = File(script).readAsStringSync();
  final codeUnit = SourceCodeUnit('dart', source, id: 'test');

  var loadOK = await vm.loadCodeUnit(codeUnit);

  if (!loadOK) {
    print("Can't load source!");
    return;
  }

  print('---------------------------------------');

  var dartRunner = vm.createRunner('dart')!;

  // map the `print` function in the VM:
  dartRunner.externalPrintFunction = (o) => print("» $o");
  // map a async function to VM
  dartRunner.externalFunctionMapper
      ?.mapExternalFunction1(ASTTypeVoid.instance, 'sleep', ASTTypeObject.instance, 'o', (o) => sleep(o as int));

  final stopwatch = Stopwatch();
  stopwatch.start();
  var astValue = await dartRunner.executeClassMethod(
    '',
    'Calc',
    'sum',
    positionalParameters: [
      [50]
    ],
  );
  final result = astValue.getValueNoContext();
  stopwatch.stop;
  print('Result: $result in ${stopwatch.elapsedMilliseconds}ms');
}

void sleep(int s) async {
  await Future<void>.delayed(Duration(seconds: s));
}
