// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:io';

import 'package:server/worker_tribble.dart';
import 'package:tribbles/tribbles.dart';

int _completedInLastSecond = 0;

Future<Tribble> createAdminTribble(dynamic message) async {
  final tribble = Tribble(adminFunction);

  // wait for tribble to be ready
  await tribble.waitForReady();
  tribble.sendMessage(message);
  return tribble;
}

Future<void> adminFunction(ConnectFn connect, ReplyFn reply) async {
  final s = connect();

  sendStatus(reply); //dont await! just start the infinite status sending loop

  s.listen((message) async {
    // TODO: listen for admin commands
    if (message == "start") {
      print("start load workers");
      createLoadWorkers(10);
    }
  });
}

Future<void> createLoadWorkers(int workerCount) async {
  for (var i = 0; i < workerCount; i += 1) {
    final tribble = await createTribble("scripts/load_maker.lua");

    tribble.messages.listen((dynamic mesg) {
      if (mesg.toString().startsWith("completed:")) {
        _completedInLastSecond++;
      }
    });
  }
  print("started $workerCount load workers");
}

Future<void> sendStatus(ReplyFn reply) async {
  // send status to parent Tribble (Isolate) at 1Hz
  print("entering status loop");
  while (true) {
    await Future<void>.delayed(Duration(seconds: 1));
    final status = Status(
      completionCount: _completedInLastSecond,
      memoryUsage: ProcessInfo.currentRss,
    );
    reply(status.toJson());
    _completedInLastSecond = 0; //reset counter
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
