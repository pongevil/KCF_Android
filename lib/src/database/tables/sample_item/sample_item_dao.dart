import 'package:bs_mobile/src/database/core/app_database.dart';
import 'package:bs_mobile/src/database/core/base_table_dao.dart';
import 'package:bs_mobile/src/database/tables/sample_item/sample_item_entity.dart';
import 'package:bs_mobile/src/database/tables/sample_item/sample_item_schema.dart';
import 'package:sqflite/sqflite.dart';

/// DAO for [SampleItemSchema] — extends [BaseTableDao] for CRUD.
class SampleItemDao extends BaseTableDao<SampleItemEntity> {
  SampleItemDao({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  @override
  Future<Database> get database => _database.database;

  @override
  String get tableName => SampleItemSchema.table;

  @override
  SampleItemEntity fromMap(Map<String, dynamic> row) {
    return SampleItemEntity(
      id: row['id'] as int?,
      code: row['code'] as String,
      name: row['name'] as String,
      updatedAt: row['updated_at'] as int,
    );
  }

  @override
  Map<String, dynamic> toMap(SampleItemEntity entity) {
    return {
      if (entity.id != null) 'id': entity.id,
      'code': entity.code,
      'name': entity.name,
      'updated_at': entity.updatedAt,
    };
  }

  Future<SampleItemEntity?> findByCode(String code) {
    return findAll(
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    ).then((rows) => rows.isEmpty ? null : rows.first);
  }
}
