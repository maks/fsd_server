import 'dart:io';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

void main(List<String> args) async {
  final wsUrl = Uri.parse('ws://localhost:9090/ws');
  var channel = WebSocketChannel.connect(wsUrl);

  channel.stream.listen((message) {
    stdout.write("recv'd:$message");
    stdout.write('> ');
  });

  stdout.write('> ');
  await stdin.forEach((input) {
    final s = String.fromCharCodes(input);
    if (s.startsWith('.exit')) {
      channel.sink.close(status.goingAway);
      exit(0);
    }
    channel.sink.add(String.fromCharCodes(input));
  });
}
