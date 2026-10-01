import 'package:bs_mobile/src/database/core/table_schema.dart';
import 'package:sqflite/sqflite.dart';

/// Initial migration — creates all tables introduced in version 1.
abstract final class MigrationV1 {
  static Future<void> up(Database db, List<TableSchema> schemas) async {
    for (final schema in schemas.where((s) => s.versionIntroduced == 1)) {
      await db.execute(schema.createTableSql);
    }
  }
}
