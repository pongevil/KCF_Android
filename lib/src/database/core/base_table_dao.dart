import 'package:sqflite/sqflite.dart';

/// Abstract CRUD base for table DAOs.
abstract class BaseTableDao<T> {
  Future<Database> get database;
  String get tableName;

  T fromMap(Map<String, dynamic> row);
  Map<String, dynamic> toMap(T entity);

  Future<int> insert(
    T entity, {
    ConflictAlgorithm conflict = ConflictAlgorithm.abort,
  }) async {
    final db = await database;
    return db.insert(tableName, toMap(entity), conflictAlgorithm: conflict);
  }

  Future<void> insertAll(
    List<T> entities, {
    ConflictAlgorithm conflict = ConflictAlgorithm.abort,
  }) async {
    final db = await database;
    final batch = db.batch();
    for (final entity in entities) {
      batch.insert(tableName, toMap(entity), conflictAlgorithm: conflict);
    }
    await batch.commit(noResult: true);
  }

  Future<int> update(
    T entity, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return db.update(
      tableName,
      toMap(entity),
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<int> delete({String? where, List<Object?>? whereArgs}) async {
    final db = await database;
    return db.delete(tableName, where: where, whereArgs: whereArgs);
  }

  Future<int> deleteAll() => delete();

  Future<T?> findById(dynamic id, {String idColumn = 'id'}) async {
    final rows = await findAll(
      where: '$idColumn = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<T>> findAll({
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    final rows = await db.query(
      tableName,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    return rows.map(fromMap).toList();
  }

  Future<int> count({String? where, List<Object?>? whereArgs}) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM $tableName'
      '${where != null ? ' WHERE $where' : ''}',
      whereArgs,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
