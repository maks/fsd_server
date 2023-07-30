# Fast Dart

## Introduction

Initially a demo of how combining Dart Isolates and a dynamic language interpreter implemented in pure Dart (Lua for now) can allow for building Erlang/Elixir style robust network server applicatons with dynamic code updates and runtime introspection and debugging features, even when AOT compiled to a stand along executable.

## Usage

A single, command-line application, stand alone exe with only system library dependencies in `bin/fsd` or can be run in debug/JIT mode using `dart bin/fsd.dart`.

### FSD Parameters

Currently `fsd` takes no parameters with everything hardcoded in the Dart code :-( This will change shortly.

### Tools

There are currently auxillary tools to aid development and debugging including a simple LUA repl in `bin/lua.dart` and a minimal websocket client in `bin/wscat.dart`.

## Features

### M1: The Demo

* [X] Lua REPL
* [X] Lua REPL on cli
* [X] Websocket cli client
* [X] Flutter web admin app served by fsd httpd
* [X] Consolidate to single Shelf based server
* [X] Run Lua workers with Tribbles
* [X] Basic Named SendPort registry
* [ ] Websocket admin API
* [ ] Websocket user API
* [ ] Flutter web admin app - display stats/graph
* [ ] Flutter web admin app - Lua repl
* [ ] Flutter Linux desktop admin app

### M2: MVP

* [ ] HTTPS & WSS (using lets encrypt shelf pkg)
* [ ] Expose "spawn" function to Lua to create & run new Tribbles
* [ ] User authentication
* [ ] User authorisation/permissions
* [ ] SQLite for K-V datastore API over websocket
* [ ] Tiny deployable Docker container (aot exe, per Dartfrog example)



## Language & Framework issues (known & fixed)

my feature request Isolate ID access without vm_serivce:
https://github.com/dart-lang/sdk/issues/52976

my feature request to access sendports from native ports:
https://github.com/dart-lang/sdk/issues/52977

VM service does not hot reload non-main Isolates (Fixed)
https://github.com/dart-lang/sdk/issues/44640

dartaotruntime help shows --observe but it does not work (Open)
https://github.com/dart-lang/sdk/issues/44651#issuecomment-1626889446

need for prem-emptive scheduling for large numbers of Isolates
https://github.com/dart-lang/sdk/issues/46752#issuecomment-1621314275