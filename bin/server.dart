import 'dart:io';

import 'package:server/isolates.dart';

void main(List<String> arguments) async {
  print('isolate test...');
  printMemUsage();

  int isoCount = 1000;

  for (var i = 0; i < isoCount; i += 1) {
    final iso = await spawn(i);
    // print("spawned isolate: $iso");
    if ((i % 100) == 0) {
      stdout.write('.');
    }
  }
  await Future<void>.delayed(Duration(seconds: 30));
  printMemUsage();
}
