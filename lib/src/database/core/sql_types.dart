/// SQLite column type constants and DDL helpers.
abstract final class SqlTypes {
  static const text = 'TEXT';
  static const integer = 'INTEGER';
  static const real = 'REAL';
  static const blob = 'BLOB';

  static const primaryKeyAuto = 'INTEGER PRIMARY KEY AUTOINCREMENT';
  static const notNull = 'NOT NULL';
}
