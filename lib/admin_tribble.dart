// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:io';

import 'package:bonsai/bonsai.dart';
import 'package:server/load_maker.dart';
import 'package:tribbles/tribbles.dart';

const logtag = "admin_tribble";

LoadMaker? _loadMaker;

Future<Tribble> createAdminTribble(dynamic message) async {
  final tribble = Tribble(adminFunction);
  Log.d(logtag, "created admin tribble");

  // wait for tribble to be ready
  await tribble.waitForReady();
  tribble.sendMessage(message);
  return tribble;
}

Future<void> adminFunction(ConnectFn connect, ReplyFn reply) async {
  Log.init(true); //need to re-init Logging in every new Isolate
  final s = connect();

  sendStatus(reply); //dont await! just start the infinite status sending loop

  s.listen((message) async {
    if (message is String && message.startsWith("start:")) {
      Log.d(logtag, "recv'd worker start message:$message");
      final int? count = int.tryParse(message.split(":")[1]);
      if (count != null) {
        Log.d(logtag, "starting load worker count:$count");
        _loadMaker ??= LoadMaker();
        await _loadMaker!.startWorkLoad(count);
      } else {
        Log.d(logtag, "INVALID worker start message count:$message");
      }
    }
  });
}

/// send status messages in infinite loop
Future<void> sendStatus(ReplyFn reply) async {
  // send status to parent Tribble (Isolate) at 1Hz
  Log.d(logtag, "entering status loop");
  while (true) {
    await Future<void>.delayed(Duration(seconds: 1));
    final status = Status(
      completionCount: _loadMaker?.getAndClearCompletionCount() ?? 0,
      memoryUsage: ProcessInfo.currentRss,
      workerCount: _loadMaker?.workerCount ?? 0,
    );
    reply(status.toJson());
  }
}

// current admin system status
class Status {
  final int completionCount;
  final int memoryUsage;
  final int workerCount;
  Status({
    required this.completionCount,
    required this.memoryUsage,
    required this.workerCount,
  });

  Status copyWith({
    int? completionCount,
    int? memoryUsage,
    int? workerCount,
  }) {
    return Status(
      completionCount: completionCount ?? this.completionCount,
      memoryUsage: memoryUsage ?? this.memoryUsage,
      workerCount: workerCount ?? this.workerCount,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'completionCount': completionCount,
      'memoryUsage': memoryUsage,
      'workerCount': workerCount,
    };
  }

  factory Status.fromMap(Map<String, dynamic> map) {
    return Status(
      completionCount: map['completionCount'] as int,
      memoryUsage: map['memoryUsage'] as int,
      workerCount: map['workerCount'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory Status.fromJson(String source) => Status.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => toJson();

  @override
  bool operator ==(covariant Status other) {
    if (identical(this, other)) return true;

    return other.completionCount == completionCount &&
        other.memoryUsage == memoryUsage &&
        other.workerCount == workerCount;
  }

  @override
  int get hashCode => completionCount.hashCode ^ memoryUsage.hashCode ^ workerCount.hashCode;
}
