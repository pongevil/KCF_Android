import 'package:bs_mobile/src/database/core/database_config.dart';
import 'package:bs_mobile/src/database/core/database_registry.dart';
import 'package:bs_mobile/src/database/migrations/migration_runner.dart';
import 'package:sqflite/sqflite.dart';

/// Singleton SQLite database manager.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    _database ??= await open();
    return _database!;
  }

  Future<Database> open() async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final path = '$dbPath/${DatabaseConfig.name}';

    _database = await openDatabase(
      path,
      version: DatabaseConfig.version,
      onCreate: (db, version) => MigrationRunner.run(
        db,
        from: 0,
        to: version,
        schemas: DatabaseRegistry.schemas,
      ),
      onUpgrade: (db, oldVersion, newVersion) => MigrationRunner.run(
        db,
        from: oldVersion,
        to: newVersion,
        schemas: DatabaseRegistry.schemas,
      ),
    );

    return _database!;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
