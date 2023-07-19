import 'dart:io';

import 'package:filesize/filesize.dart';
import 'package:tribbles/tribbles.dart';

class FSDServer {
  Future<void> run() async {
    print('Tribble test...');
    printMemUsage();

    int isoCount = 10000;
    int replyCount = 0;

    final startTime = DateTime.now();
    for (var i = 0; i < isoCount; i += 1) {
      final tribble = await createTribble();
      
      tribble.messages.listen((mesg) {
        if (mesg != 42) {
          stdout.write('x:${mesg.runtimeType}');
        }
        replyCount++;
      });
    }
    print('\nfinished spawning ${Tribble.tribbleCount} tribbles in: ${elapsedMs(startTime)}ms');
    while (replyCount != isoCount) {
      await Future<void>.delayed(Duration(microseconds: 10));
    }
    await Future<void>.delayed(Duration(seconds: 10));

    print('[${Tribble.tribbleCount}] received replies in: ${elapsedMs(startTime)}ms');
    printMemUsage();
    exit(0);
  }
}

int elapsedMs(DateTime start) => DateTime.now().millisecondsSinceEpoch - start.millisecondsSinceEpoch;

Future<Tribble> createTribble() async {
  final tribble = Tribble(hi);

  // wait for tribble to be ready
  await tribble.waitForReady();
  tribble.sendMessage('.');
  return tribble;
}

Future<void> hi(ConnectFn connect, ReplyFn reply) async {
  final s = connect();
  s.listen((message) async {
    final res = calculate();
    reply(res);

    await Future<void>.delayed(Duration(seconds: 3));
    s.close();
  });
}

int calculate() {
  return 6 * 7;
}

void printMemUsage() {
  final currentRss = ProcessInfo.currentRss;
  final maxRss = ProcessInfo.maxRss;
  print('\nRSS current:${filesize(currentRss)} max:${filesize(maxRss)}');
}
