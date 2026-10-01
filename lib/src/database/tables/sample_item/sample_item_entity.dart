/// Row model for [SampleItemSchema].
class SampleItemEntity {
  const SampleItemEntity({
    this.id,
    required this.code,
    required this.name,
    required this.updatedAt,
  });

  final int? id;
  final String code;
  final String name;
  final int updatedAt;

  SampleItemEntity copyWith({
    int? id,
    String? code,
    String? name,
    int? updatedAt,
  }) {
    return SampleItemEntity(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
