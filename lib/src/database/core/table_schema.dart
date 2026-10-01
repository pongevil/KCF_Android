/// Contract for a single SQLite table definition.
abstract class TableSchema {
  String get tableName;
  String get createTableSql;
  int get versionIntroduced;
}
