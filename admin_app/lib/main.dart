import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:simple_line_chart/simple_line_chart.dart';
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

class _UserViewState extends State<UserView> with AutomaticKeepAliveClientMixin<UserView> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> results = [];

  final _channel = WebSocketChannel.connect(
    Uri.parse('ws://127.0.0.1:9090/ws'),
  );

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    // needed for AutomaticKeepAliveClientMixin
    super.build(context); 

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
            if (snapshot.hasData) {
              results = jsonDecode(snapshot.data) as List<dynamic>;
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: ListView.builder(
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("∑(1..${results[i][0]}) = ${results[i][1]}"),
                  ),
                  itemCount: results.length,
                ),
              );
            } else {
              return const Text("no results");
            }
          },
        ),
      ],
    );
  }

  void _sendMessage(String input) {
    if (_controller.text.isNotEmpty) {
      debugPrint("submit:$input");
      _channel.sink.add(input);
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

class _AdminViewState extends State<AdminView> with AutomaticKeepAliveClientMixin<AdminView> {
  final _adminChannel = WebSocketChannel.connect(
    Uri.parse('ws://127.0.0.1:9999/ws'),
  );

  final List<DataPoint> _memoryReadings = [];
  final List<DataPoint> _completionReadings = [];

  late final LineChartData memData;
  late final LineChartData compsData;
  int _dataCounter = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // create a data model
    memData = LineChartData(datasets: [
      Dataset(label: 'Memory', dataPoints: _memoryReadings),
    ]);

    compsData = LineChartData(datasets: [
      Dataset(label: 'Completions', dataPoints: _completionReadings),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    // needed for AutomaticKeepAliveClientMixin
    super.build(context); 
    
    return StreamBuilder(
      stream: _adminChannel.stream,
      builder: (context, snapshot) {
        if (snapshot.data != null) {
          final json = jsonDecode(snapshot.data);
          final int mem = json["memoryUsage"]; //todo proper typed json parsing
          final int comps = json["completionCount"]; //todo proper typed json parsing
          _memoryReadings.add(DataPoint(y: mem.toDouble(), x: (_dataCounter++).toDouble()));
          if (comps > 0) {
            _completionReadings.add(DataPoint(y: comps.toDouble(), x: _dataCounter.toDouble()));
          }
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: 300,
                child: Row(
                  children: [
                    SizedBox(
                      width: 300,
                      child: LineChart(
                        style: LineChartStyle.fromTheme(context)
                            .copyRemoving(
                          topAxis: true,
                          rightAxis: true,
                        )
                            .copyWith(
                          datasetStyles: [DatasetStyle(color: Colors.redAccent)],
                          bottomAxisStyle: LineChartStyle.fromTheme(context).bottomAxisStyle?.copyWith(labelCount: 0),
                        ),
                        data: memData,
                        seriesHeight: 200,
                      ),
                    ),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 300,
                      child: LineChart(
                        style: LineChartStyle.fromTheme(context)
                            .copyRemoving(
                              topAxis: true,
                              rightAxis: true,
                            )
                            .copyWith(
                              bottomAxisStyle:
                                  LineChartStyle.fromTheme(context).bottomAxisStyle?.copyWith(labelCount: 0),
                            ),
                        data: compsData,
                        seriesHeight: 200,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Text(snapshot.hasData ? 'Data [$_dataCounter]:${snapshot.data}' : 'No Data'),
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
      debugPrint("send admin:start:$input");
      _adminChannel.sink.add("start:$input");
    }
  }

  @override
  void dispose() {
    _adminChannel.sink.close();
    super.dispose();
  }
  
}
