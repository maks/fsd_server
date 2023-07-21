import 'dart:io';

class WSServer {
  late final HttpServer _server;

  Future<void> start(int port) async {
    const path = '/ws';
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    print('-- WS server listening on localhost:${_server.port} path:$path');

    await for (HttpRequest request in _server) {
      if (request.uri.path == path) {
        // Upgrade an HttpRequest to a WebSocket connection
        final socket = await WebSocketTransformer.upgrade(request);
        print('Client connected!');

        // Listen for incoming messages from the client
        socket.listen((message) {
          print('Received message: $message');
          socket.add('You sent: $message');
        });
      } else {
        print("forbidden:$request");
        request.response.statusCode = HttpStatus.forbidden;
        request.response.close();
      }
    }
  }

  void stop() {
    _server.close();
  }
}
