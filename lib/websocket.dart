import 'dart:io';

class WSServer {
  late final HttpServer _server;

  Future<void> start(int port) async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    print('Listening on localhost:${_server.port}');

    await for (HttpRequest request in _server) {
      if (request.uri.path == '/ws') {
        // Upgrade an HttpRequest to a WebSocket connection
        final socket = await WebSocketTransformer.upgrade(request);
        print('Client connected!');

        // Listen for incoming messages from the client
        socket.listen((message) {
          print('Received message: $message');
          socket.add('You sent: $message');
        });
      } else {
        request.response.statusCode = HttpStatus.forbidden;
        request.response.close();
      }
    }
  }

  void stop() {
    _server.close();
  }
}
