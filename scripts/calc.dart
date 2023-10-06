class Calc {
  int sum(List<Object> args) {
    var sumTo = args[0];

    if (sumTo == 13) {
      print("unlucky number!");
      invalid();
    }

    int accum = 0;
    for (int i = 0; i <= sumTo; i += 1) {
      accum = accum + i;
    }
    // print("acc: $sumTo -> $accum");
    return accum;
  }

  // non-std Dart, no need for async
  void loop(List<Object> args) {
    // non-std Dart, cant have empty for(;;;)
    for (true; true; true) {
      int result = sum(args);
      send("$result");
      sleep(1000); // non-std Dart, no need for await
    }
  }
}
