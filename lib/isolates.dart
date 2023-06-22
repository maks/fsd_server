import 'dart:io';
import 'dart:isolate';

import 'package:filesize/filesize.dart';

int calculate() {
  return 6 * 7;
}

void printMemUsage() {
  final currentRss = ProcessInfo.currentRss;
  final maxRss = ProcessInfo.maxRss;
  print('\nRSS current:${filesize(currentRss)} max:${filesize(maxRss)}');
}

Future<Isolate> spawn(int id) async {
  return Isolate.spawn((pid) async {
    while (true) {
      await Future<void>.delayed(Duration(seconds: 1));
      //print("worker [$id] finished");
      if ((id % 100) == 0) {
        stdout.write('+$pid-');
      }
    }
  }, id);
}
