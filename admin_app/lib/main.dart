import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.person)),
              Tab(icon: Icon(Icons.settings)),
            ],
          ),
        ),
        body: const Center(
          child: TabBarView(
            children: <Widget>[
              UserView(),
              AdminView(),
            ],
          ),
        ),
      ),
    );
  }
}

class UserView extends StatefulWidget {
  const UserView({super.key});

  @override
  State<UserView> createState() => _UserViewState();
}

class _UserViewState extends State<UserView> {
  final TextEditingController _controller = TextEditingController();

  final _channel = WebSocketChannel.connect(
    Uri.parse('ws://localhost:9090/ws'),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Form(
          child: TextFormField(
            controller: _controller,
            decoration: const InputDecoration(labelText: 'Input:'),
            onFieldSubmitted: (String s) => _sendMessage(s),
          ),
        ),
        const SizedBox(height: 24),
        StreamBuilder(
          stream: _channel.stream,
          builder: (context, snapshot) {
            return Text(snapshot.hasData ? '${snapshot.data}' : '');
          },
        ),
      ],
    );
  }

  void _sendMessage(String input) {
    if (_controller.text.isNotEmpty) {
      print("submit:$input");
      // _channel.sink.add("start:$input");
    }
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }
}

class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  final _adminChannel = WebSocketChannel.connect(
    Uri.parse('ws://localhost:9999/ws'),
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _adminChannel.stream,
      builder: (context, snapshot) {
        return Column(
          children: [
            const Placeholder(fallbackHeight: 240, fallbackWidth: 320),
            Text(snapshot.hasData ? 'COMP:${snapshot.data}' : ''),
            Form(
              child: TextFormField(
                decoration: const InputDecoration(labelText: 'Jobs:'),
                onFieldSubmitted: (String s) => _sendAdminMessage(s),
              ),
            ),
          ],
        );
      },
    );
  }

  void _sendAdminMessage(String input) {
    if (input.isNotEmpty) {
      print("send admin:start:$input");
      _adminChannel.sink.add("start:$input");
    }
  }

  @override
  void dispose() {
    _adminChannel.sink.close();
    super.dispose();
  }
}
