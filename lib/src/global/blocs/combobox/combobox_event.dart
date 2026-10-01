part of 'combobox_bloc.dart';

sealed class ComboboxEvent extends Equatable {
  const ComboboxEvent();

  @override
  List<Object?> get props => [];
}

final class FetchComboboxEvent extends ComboboxEvent {
  const FetchComboboxEvent({
    required this.group_name,
    this.forceRefresh = false,
  });

  final bool forceRefresh;
  final String group_name;

  @override
  List<Object?> get props => [forceRefresh, group_name];
}
