import 'package:bs_mobile/src/database/core/table_schema.dart';
import 'package:bs_mobile/src/database/tables/sample_item/sample_item_schema.dart';

/// Central registry of all table schemas.
///
/// To add a new table:
/// 1. Create `tables/<name>/` with schema, entity, dao
/// 2. Add schema to [schemas]
/// 3. Bump [DatabaseConfig.version] and add migration if needed
///
/// Locale strings use JSON file cache via [LocaleRepository], not SQLite.
/// [SampleItemSchema] is a template table for new DAO work.
abstract final class DatabaseRegistry {
  static final List<TableSchema> schemas = [SampleItemSchema.instance];
}
