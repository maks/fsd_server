A sample command-line application with an entrypoint in `bin/`, library code
in `lib/`, and example unit test in `test/`.


## Features

### M1: The Demo

* [X] Lua REPL
* [X] Lua REPL on cli
* [X] websocket cli client
* [ ] websocket admin API
* [ ] websocket user API
* [ ] Flutter web admin app
* [ ] Flutter web admin app - display stats/graph
* [ ] Flutter web admin app - Lua repl
* [ ] Flutter Linux desktop admin app

### M2: MVP

* [ ] Sqlite for K-V datastore API over websocket
* [ ] Tiny deployable Docker container (aot exe)



## Issues known & fixed

my feature request Isolate ID access without vm_serivce:
https://github.com/dart-lang/sdk/issues/52976

my feature request to access sendports from native ports:
https://github.com/dart-lang/sdk/issues/52977

VM service does not hot reload non-main Isolates (Fixed)
https://github.com/dart-lang/sdk/issues/44640


dartaotruntime help shows --observe but it does not work (Open)
https://github.com/dart-lang/sdk/issues/44651#issuecomment-1626889446

