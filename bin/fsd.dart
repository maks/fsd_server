import 'dart:io';

import 'package:bonsai/bonsai.dart';
import 'package:server/admin_tribble.dart';
import 'package:server/lua_worker_tribble.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:tribbles/tribbles.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const logtag = "fsdmain";

void main(List<String> arguments) async {
  const debug = true;
  if (debug) {
    Log.init(true);
  }
  
  final wsHandler = webSocketHandler((WebSocketChannel webSocket) {
    webSocket.stream.listen((message) async {
      Log.d(logtag, 'Received WS message: $message');

      final tribble = await createLuaWorkerTribble("scripts/worker.lua");
      tribble.messages.listen((dynamic m) {
        // messages from the tribble worker get sent straight out to the websocket
        webSocket.sink.add('$tribble]$m');
      });
    });
  });

  Tribble? adminTribble;
  final adminWSHandler = webSocketHandler((WebSocketChannel webSocket) async {
    webSocket.stream.listen((message) async {
      Log.d(logtag, 'Received WS message: $message');
      adminTribble?.sendMessage(message);
    });

    if (adminTribble == null) {
      // for now only start admin Tribble when an admin client connects via websocket
      adminTribble = await createAdminTribble("start");

      adminTribble!.messages.listen((dynamic m) {
        // messages from the admin tribble get sent straight out to the websocket
        // where admin clients are connected
        webSocket.sink.add(m);
        Log.d(logtag, "sent update:$m");
      });
    }
  });

  // separate port for "user" websockets for now
  final wsServer = await shelf_io.serve(wsHandler, 'localhost', 9090);
  Log.d(logtag, 'Serving at Users on ws://${wsServer.address.host}:${wsServer.port}');

  // separate port for "admin" websockets for now
  final adminWSServer = await shelf_io.serve(adminWSHandler, 'localhost', 9999);
  Log.d(logtag, 'Serving at Admin on ws://${adminWSServer.address.host}:${adminWSServer.port}');

  // serve admin web app with HTTP on different port
  final adminAppPath = Directory('admin_app/build/web');
  final staticHandler = createStaticHandler(adminAppPath.path, defaultDocument: 'index.html');
  final staticServer = await shelf_io.serve(staticHandler, 'localhost', 8080);
  // Enable content compression
  staticServer.autoCompress = true;
  Log.d(logtag, 'Serving at http://${staticServer.address.host}:${staticServer.port}');
}
