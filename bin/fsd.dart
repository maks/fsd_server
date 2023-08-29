// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';
import 'dart:isolate';

import 'package:bonsai/bonsai.dart';
import 'package:isolate_name_server/isolate_name_server.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:tribbles/tribbles.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:server/admin_tribble.dart';
import 'package:server/isolate_worker.dart';
import 'package:server/names.dart';

const logtag = "fsdmain";

int _userRequestIdCounter = 0;
Map<int, ({int req, int sum})> _userRequestsById = {};

List<WebSocketSink> _socketSinks = [];

void main(List<String> arguments) async {
  const debug = true;
  if (debug) {
    Log.init(true);
  }
  
  final userWSHandler = webSocketHandler((WebSocketChannel webSocket) {
    ReceivePort rp = ReceivePort();
    // register port so that job isolates can look it up when they need to report their completion result
    IsolateNameServer.registerPortWithName(rp.sendPort, userJobPortName);

    rp.listen((message) {
      Log.d(logtag, "got user job result:$message");
      final mesg = message.toString().split(":");
      final id = int.tryParse(mesg[0]);
      final result = int.parse(mesg[1]);
      if (id != null && mesg.length == 2) {
        _userRequestsById[id] = (req: _userRequestsById[id]!.req, sum: result);
        Log.d(logtag, "sent: [$id]:${mesg[1]}");
      } else {
        Log.e(logtag, "invalid user response id:$mesg[0]");
      }
      final resultsList = _userRequestsById.values.map((e) => "[${e.req},${e.sum}]").toList();

      for (final sink in _socketSinks) {
        sink.add("$resultsList");
      }
    });

    webSocket.stream.listen((message) async {
      Log.d(logtag, 'Received user WS message: $message');
      final chunk = await File("scripts/calc.lua").readAsString();
      final userReqInput = int.parse(message as String);
      final LuaRequestData data = (id: _userRequestIdCounter, luaChunk: chunk);
      _userRequestsById[_userRequestIdCounter] = (req: userReqInput, sum: 0);
      _userRequestIdCounter++;
      _socketSinks.add(webSocket.sink);
      runLuaIsolateJob(data, "runLuaIsolateJob");     
    });
  });

  Tribble? adminTribble;
  final adminWSHandler = webSocketHandler((WebSocketChannel webSocket) async {
    Log.i(logtag, "new Admin WS connection");

    webSocket.stream.listen((message) async {
      Log.d(logtag, 'Received WS message: $message');
      adminTribble?.sendMessage(message);
    });

    // create new admin tribble if one doesn't yet exist
    adminTribble ??= await createAdminTribble("start"); 

    adminTribble!.messages.listen((dynamic m) {
        // messages from the admin tribble get sent straight out to the websocket
        // where admin clients are connected
        webSocket.sink.add(m);
      // Log.d(logtag, "sent update:$m");
    });
  });

  // separate port for "user" websockets for now
  final wsServer = await shelf_io.serve(userWSHandler, 'localhost', 9090);
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
