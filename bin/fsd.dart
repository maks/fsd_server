import 'dart:io';

import 'package:server/admin_tribble.dart';
import 'package:server/worker_tribble.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main(List<String> arguments) async {
  final wsHandler = webSocketHandler((WebSocketChannel webSocket) {
    webSocket.stream.listen((message) async {
      // print('Received WS message: $message');

      final tribble = await createTribble("scripts/worker.lua");
      tribble.messages.listen((dynamic m) {
        // messages from the tribble worker get sent straight out to the websocket
        webSocket.sink.add('$tribble]$m');
      });
    });
  });

  final adminWSHandler = webSocketHandler((WebSocketChannel webSocket) async {
    webSocket.stream.listen((message) async {
      // print('Received WS message: $message');
      // TODO: handle incoming admin command messages
    });

    // for now only start admin Tribble when an admin client connects via websocket
    final tribble = await createAdminTribble("start");
    tribble.messages.listen((dynamic m) {
      // messages from the admin tribble get sent straight out to the websocket
      // where admin clients are connected
      webSocket.sink.add(m);
      print("sent update:$m");
    });
  });

  // separate port for "user" websockets for now
  final wsServer = await shelf_io.serve(wsHandler, 'localhost', 9090);
  print('Serving at Users on ws://${wsServer.address.host}:${wsServer.port}');

  // separate port for "admin" websockets for now
  final adminWSServer = await shelf_io.serve(adminWSHandler, 'localhost', 9999);
  print('Serving at Admin on ws://${adminWSServer.address.host}:${adminWSServer.port}');

  // serve admin web app with HTTP on different port
  final adminAppPath = Directory('admin_app/build/web');
  final staticHandler = createStaticHandler(adminAppPath.path, defaultDocument: 'index.html');
  final staticServer = await shelf_io.serve(staticHandler, 'localhost', 8080);
  // Enable content compression
  staticServer.autoCompress = true;
  print('Serving at http://${staticServer.address.host}:${staticServer.port}');
}
