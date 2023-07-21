// import 'package:server/test_server.dart';
import 'package:server/websocket_server.dart';

void main(List<String> arguments) async {
  // final server = FSDServer();
  final server = WSServer();

  await server.start(9090);
}
