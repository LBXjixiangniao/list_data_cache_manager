import 'dart:io';
import 'dart:isolate';

import 'package:list_data_cache_manager/cache_item_model/list_item.dart';
import 'package:moor/ffi.dart';
import 'package:moor/isolate.dart';
import 'package:moor/moor.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/**  不开启isolate */
// this annotation tells moor to prepare a database class that uses both of the
// tables we just defined. We'll see how to use that database class in a moment.
LazyDatabase _openConnection() {
  // the LazyDatabase util lets us find the right location for the file async.
  return LazyDatabase(() async {
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    final dbFolder = await getApplicationDocumentsDirectory();
    assert(() {
      print(dbFolder.path);
      return true;
    }());
    final file = File(p.join(dbFolder.path, 'lbx_db.sqlite'));
    return VmDatabase(file);
  });
}

/**  开启isolate */
Future<MoorIsolate> _createMoorIsolate() async {
  // this method is called from the main isolate. Since we can't use
  // getApplicationDocumentsDirectory on a background isolate, we calculate
  // the database path in the foreground isolate and then inform the
  // background isolate about the path.
  final dir = await getApplicationDocumentsDirectory();
  final path = p.join(dir.path, 'lbx_db.sqlite');
  final receivePort = ReceivePort();

  await Isolate.spawn(
    _startBackground,
    _IsolateStartRequest(receivePort.sendPort, path),
  );

  // _startBackground will send the MoorIsolate to this ReceivePort
  return (await receivePort.first as MoorIsolate);
}

void _startBackground(_IsolateStartRequest request) {
  // this is the entry point from the background isolate! Let's create
  // the database from the path we received
  final executor = VmDatabase(File(request.targetPath));
  // we're using MoorIsolate.inCurrent here as this method already runs on a
  // background isolate. If we used MoorIsolate.spawn, a third isolate would be
  // started which is not what we want!
  final moorIsolate = MoorIsolate.inCurrent(
    () => DatabaseConnection.fromExecutor(executor),
  );
  // inform the starting isolate about this, so that it can call .connect()
  request.sendMoorIsolate.send(moorIsolate);
}

// used to bundle the SendPort and the target path, since isolate entry point
// functions can only take one parameter.
class _IsolateStartRequest {
  final SendPort sendMoorIsolate;
  final String targetPath;

  _IsolateStartRequest(this.sendMoorIsolate, this.targetPath);
}

Future<DatabaseConnection> _connectAsync() async {
  MoorIsolate isolate = await _createMoorIsolate();
  return isolate.connect();
}

@UseMoor(tables: [CacheDBItems], daos: [CacheDBItemsDao])
class LbxDatabase extends _$LbxDatabase {
  // we tell the database where to store the data with this constructor
  static LbxDatabase _share = LbxDatabase.connect(DatabaseConnection.delayed(_connectAsync()));
  static LbxDatabase get share => _share;
  factory LbxDatabase() => _share;
  LbxDatabase._() : super(_openConnection());
  LbxDatabase.connect(DatabaseConnection connection) : super.connect(connection);

  // you should bump this number whenever you change or add a table definition. Migrations
  // are covered later in this readme.
  @override
  int get schemaVersion => 1;
}
