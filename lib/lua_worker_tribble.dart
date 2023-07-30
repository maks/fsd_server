import 'package:isolate_name_server/isolate_name_server.dart';
import 'package:tribbles/tribbles.dart';

import 'lua_worker.dart';

Future<Tribble> createLuaWorkerTribble(dynamic message, {bool persist = false}) async {
  final tribble = Tribble(persist ? persistentWorkerFunction : workerFunction);

  // wait for tribble to be ready
  await tribble.waitForReady();

  tribble.sendMessage(message);
  return tribble;
}


Future<void> workerFunction(ConnectFn connect, ReplyFn reply) async {
  final s = connect();
  // expect message to be the Lua chunk to execute
  s.listen(
    (dynamic message) {
      // we give the Lua worker a send function that just immediately sends the data
      // out to the messages stream of this Tribble
      LuaWorker(
        chunk: message as String,
        sendFn: (d) {
          reply(d);
        },
        data: {},
      ).run("");
      s.close();
    },
  );
}

Future<void> persistentWorkerFunction(ConnectFn connect, ReplyFn reply) async {
  final s = connect();
  // expect message to be the Lua chunk to execute
  s.listen(
    (dynamic message) async {
      // we give the Lua worker a send function that just immediately sends the data
      // out to the messages stream of this Tribble
      LuaWorker(
        chunk: message as String,
        sendFn: (d) async {
          final ins = IsolateNameServer.lookupPortByName("loadmaker");
          if (ins != null) {
            ins.send(message);
            await Future<void>.delayed(Duration(seconds: 1));
          } else {
            throw Exception("missing loadmaker Port name");
          }
        },
        data: {},
      ).run("");
    },
  );
}
