import 'dart:io';

import 'package:server/tribble_worker.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main(List<String> arguments) async {
  
  final wsHandler = webSocketHandler((WebSocketChannel webSocket) {
    webSocket.stream.listen((message) async {
      // print('Received WS message: $message');

      final tribble = await createTribble(message);
      tribble.messages.listen((dynamic m) {
        // messages from the tribble worker get sent straight out to the websocket
        webSocket.sink.add('$tribble]$m');
      });
    });
  });

  // separate port for websockets for now
  final wsServer = await shelf_io.serve(wsHandler, 'localhost', 9090);
  print('Serving at ws://${wsServer.address.host}:${wsServer.port}');

  final adminAppPath = Directory('admin_app/build/web');
  final staticHandler = createStaticHandler(adminAppPath.path, defaultDocument: 'index.html');
  final staticServer = await shelf_io.serve(staticHandler, 'localhost', 8080);
  // Enable content compression
  staticServer.autoCompress = true;
  print('Serving at http://${staticServer.address.host}:${staticServer.port}');
}

