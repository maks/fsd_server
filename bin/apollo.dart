import 'dart:convert';
import 'dart:io';

import 'package:server/apollo_repl.dart';

void main(List<String> args) async {
  stdout.write('ApolloVM Ctrl-d to exit\n');

  final Stream<String> input = stdin.transform(utf8.decoder).transform(const LineSplitter());

  ApolloVMRepl(input, (String s) => stdout.write("$s\n"), debugLogging: false).repl();
}
