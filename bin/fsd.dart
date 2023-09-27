import 'package:bonsai/bonsai.dart';
import 'package:server/ws_server.dart';


const logtag = "fsdmain";


void main(List<String> arguments) async {
  const debug = true;
  if (debug) {
    Log.init(true);
  }
  
  await wsServe();  
}
