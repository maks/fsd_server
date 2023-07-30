// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:io';

import 'package:bonsai/bonsai.dart';
import 'package:server/load_maker.dart';
import 'package:tribbles/tribbles.dart';

const logtag = "admin_tribble";

LoadMaker? _load;

Future<Tribble> createAdminTribble(dynamic message) async {
  final tribble = Tribble(adminFunction);

  // wait for tribble to be ready
  await tribble.waitForReady();
  tribble.sendMessage(message);
  return tribble;
}

Future<void> adminFunction(ConnectFn connect, ReplyFn reply) async {
  Log.init(true); //need to do init in every new Isolate
  final s = connect();

  sendStatus(reply); //dont await! just start the infinite status sending loop

  s.listen((message) async {
    if (message is String && message.startsWith("start:")) {
      Log.d(logtag, "worker start message:$message");
      final int? count = int.tryParse(message.split(":")[1]);
      if (count != null) {
        Log.d(logtag, "starting load worker count:$count");
        _load ??= LoadMaker();
        await _load!.startWorkLoad(count);
      } else {
        Log.d(logtag, "INVALID worker start message count:$message");
      }
    }
  });
}

Future<void> sendStatus(ReplyFn reply) async {
  // send status to parent Tribble (Isolate) at 1Hz
  Log.d(logtag, "entering status loop");
  while (true) {
    await Future<void>.delayed(Duration(seconds: 1));
    final status = Status(
      completionCount: _load?.getAndClearCompletionCount() ?? 0,
      memoryUsage: ProcessInfo.currentRss,
    );
    reply(status.toJson());
  }
}

// current admin system status
class Status {
  final int completionCount;
  final int memoryUsage;
  Status({
    required this.completionCount,
    required this.memoryUsage,
  });

  Status copyWith({
    int? completionCount,
    int? memoryUsage,
  }) {
    return Status(
      completionCount: completionCount ?? this.completionCount,
      memoryUsage: memoryUsage ?? this.memoryUsage,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'completionCount': completionCount,
      'memoryUsage': memoryUsage,
    };
  }

  factory Status.fromMap(Map<String, dynamic> map) {
    return Status(
      completionCount: map['completionCount'] as int,
      memoryUsage: map['memoryUsage'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory Status.fromJson(String source) => Status.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => toJson();

  @override
  bool operator ==(covariant Status other) {
    if (identical(this, other)) return true;

    return other.completionCount == completionCount && other.memoryUsage == memoryUsage;
  }

  @override
  int get hashCode => completionCount.hashCode ^ memoryUsage.hashCode;
}
