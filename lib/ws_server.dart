import 'dart:convert';
import 'dart:isolate';
import 'dart:io';

import 'package:bonsai/bonsai.dart';
import 'package:isolate_name_server/isolate_name_server.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:tribbles/tribbles.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:server/admin_tribble.dart';
import 'package:server/isolate_worker.dart';
import 'package:server/port_names.dart';

int _userRequestIdCounter = 0;
Map<int, ({int req, String sum})> _userRequestsById = {};

List<WebSocketSink> _socketSinks = [];

void sendListofUserResults() {
  // send results list to user
  final resultsList = _userRequestsById.values.map((e) => [e.req, e.sum]).toList();
  for (final sink in _socketSinks) {
    sink.add(jsonEncode(resultsList));
  }
}

Future<void> wsServe() async {
  final userWSHandler = webSocketHandler((WebSocketChannel webSocket) {
    ReceivePort rp = ReceivePort();
    // register port so that job isolates can look it up when they need to report their completion result
    IsolateNameServer.registerPortWithName(rp.sendPort, userJobPortName);

    // listen for results to user calc job requests coming from user job Isolates
    rp.listen((message) {
      Log.d(logtag, "got user job result:$message");
      final mesg = message.toString().split(":");
      final id = int.tryParse(mesg[0]);
      final result = mesg[1];
      if (id != null && mesg.length == 2) {
        _userRequestsById[id] = (req: _userRequestsById[id]!.req, sum: result);
        Log.d(logtag, "sent: [$id]:${mesg[1]}");
      } else {
        Log.e(logtag, "invalid user response id:$mesg[0]");
      }

      sendListofUserResults();
    });

    webSocket.stream.listen((message) async {
      Log.d(logtag, 'Received user WS message: $message');
      final chunk = await File("scripts/calc.lua").readAsString();
      final userReqInput = int.parse(message as String);
      final LuaRequestData data = (
        pid: _userRequestIdCounter,
        luaChunk: chunk,
        outputPortName: userJobPortName,
        input: {"sum_to": userReqInput},
      );
      _userRequestsById[_userRequestIdCounter] = (req: userReqInput, sum: "calculating...");
      _userRequestIdCounter++;

      // add this socket to list that receives broadcasts of the user results lists as we send results to all sockets
      _socketSinks.add(webSocket.sink);

      // send latest results immediately to let user know requested calc is in-progress status
      sendListofUserResults();

      // and now run the job
      runLuaIsolateJob(data);
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
  Log.d(logtag, 'Serving at Users on ws://${wsServer.address.address}:${wsServer.port}');

  // separate port for "admin" websockets for now
  final adminWSServer = await shelf_io.serve(adminWSHandler, 'localhost', 9999);
  Log.d(logtag, 'Serving at Admin on ws://${adminWSServer.address.address}:${adminWSServer.port}');

  // serve admin web app with HTTP on different port
  final adminAppPath = Directory('admin_app/build/web');
  final staticHandler = createStaticHandler(adminAppPath.path, defaultDocument: 'index.html');
  final staticServer = await shelf_io.serve(staticHandler, 'localhost', 8080);
  // Enable content compression
  staticServer.autoCompress = true;
  Log.d(logtag, 'Serving at http://${staticServer.address.address}:${staticServer.port}');
}
