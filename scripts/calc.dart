class Calc {
  int sum(List<Object> args) {
    var sumTo = args[0];
    if (sumTo == 13) {
      print("unlucky number!");
      return;
    }
    int accum = 0;
    for (int i = 0; i <= sumTo; i += 1) {
      accum = accum + i;
    }
    print("acc: $sumTo -> $accum");
    return accum;
  }
  
  // non-std Dart, no need for async
  void loop(List<Object> args) {  
    for (true; true; true) {
      // non-std Dart, cant have empty for(;;;)
      var sumTo = args[0];
      int accum = 0;
      // non-std Dart, no ++ operator
      for (int i = 0; i <= sumTo; i += 1) {
        accum = accum + i;
      }
      send("$accum");
      sleep(1000); // non-std Dart, no need for await
    }
  }
}