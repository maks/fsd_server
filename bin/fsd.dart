// import 'package:server/test_server.dart';
import 'dart:io';

import 'package:petit_httpd/petit_httpd.dart';
import 'package:server/websocket_server.dart';

void main(List<String> arguments) async {
  // final server = FSDServer();
  
  // start websocket server
  final server = WSServer();
  server.start(9090);

  var petitHTTPD = PetitHTTPD(
    Directory('admin_app'),
    port: 8080,
    // securePort: 443,
    bindingAddress: '0.0.0.0',
    // letsEncryptDirectory: Directory('/etc/letsencrypt/live'),
    // domains: {
    //   'fastdart.dev': 'contact@fastdart.dev',
    // },
  );

  final ok = await petitHTTPD.start();
  if (!ok) {
    print('** ERROR Starting: $petitHTTPD');
    exit(1);
  }

  print('-- HTTP server listening on localhost:${petitHTTPD.port} docs:${petitHTTPD.documentRoot.path}');
}
