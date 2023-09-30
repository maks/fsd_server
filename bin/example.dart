import 'package:lua_dardo/lua.dart';

void main(List<String> arguments) async {
  LuaState state = LuaState.newState();
  await state.openLibs();
  await state.loadString(r'''
a=10
while( a < 20 ) do
   print("a value is", a)
   a = a+1
end
''');
  state.pCall(0, 0, 1);
}
