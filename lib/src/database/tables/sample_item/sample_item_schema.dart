import 'package:bs_mobile/src/database/core/sql_types.dart';
import 'package:bs_mobile/src/database/core/table_schema.dart';

/// Example table schema — copy this folder when adding a new table.
class SampleItemSchema implements TableSchema {
  const SampleItemSchema._();

  static const instance = SampleItemSchema._();
  static const table = 'sample_item';

  @override
  String get tableName => table;

  @override
  int get versionIntroduced => 1;

  @override
  String get createTableSql =>
      '''
CREATE TABLE IF NOT EXISTS $tableName (
  id ${SqlTypes.primaryKeyAuto},
  code ${SqlTypes.text} ${SqlTypes.notNull},
  name ${SqlTypes.text} ${SqlTypes.notNull},
  updated_at ${SqlTypes.integer} ${SqlTypes.notNull}
)
''';
}
