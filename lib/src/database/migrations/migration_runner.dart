import 'package:bs_mobile/src/database/core/table_schema.dart';
import 'package:bs_mobile/src/database/migrations/migration_v1.dart';
import 'package:sqflite/sqflite.dart';

/// Runs incremental migrations from [from] to [to].
abstract final class MigrationRunner {
  static Future<void> run(
    Database db, {
    required int from,
    required int to,
    required List<TableSchema> schemas,
  }) async {
    for (var version = from + 1; version <= to; version++) {
      await _migrateTo(db, version, schemas);
    }
  }

  static Future<void> _migrateTo(
    Database db,
    int version,
    List<TableSchema> schemas,
  ) async {
    switch (version) {
      case 1:
        await MigrationV1.up(db, schemas);
      default:
        throw StateError('Unknown migration version: $version');
    }
  }
}
