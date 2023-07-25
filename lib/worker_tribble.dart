import 'dart:io';

import 'package:tribbles/tribbles.dart';

import 'lua_worker.dart';

Future<Tribble> createTribble(dynamic message) async {
  final tribble = Tribble(workerFunction);

  // wait for tribble to be ready
  await tribble.waitForReady();
  tribble.sendMessage(message);
  return tribble;
}

Future<void> workerFunction(ConnectFn connect, ReplyFn reply) async {
  final s = connect();
  s.listen((dynamic message) async {
    final script = File(message as String).readAsStringSync();
    // we give the Lua worker a send function that just immediately sends the data
    // out to the messages stream of this Tribble
    LuaWorker(chunk: script, sendFn: (d) => reply(d), data: {}).run(message.toString());

    await Future<void>.delayed(Duration(seconds: 3));
    s.close();
  });
}
