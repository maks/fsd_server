import 'package:server/server.dart';

void main(List<String> arguments) async {
  final server = FSDServer();

  await server.run();
}
