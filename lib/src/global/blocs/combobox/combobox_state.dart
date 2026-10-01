part of 'combobox_bloc.dart';

sealed class ComboboxState extends Equatable {
  const ComboboxState();

  List<ComboboxModel> get items => const [];

  @override
  List<Object?> get props => [];
}

final class ComboboxInitial extends ComboboxState {
  const ComboboxInitial();
}

final class ComboboxLoading extends ComboboxState {
  const ComboboxLoading({this.items = const []});

  @override
  final List<ComboboxModel> items;

  @override
  List<Object?> get props => [items];
}

final class ComboboxLoaded extends ComboboxState {
  const ComboboxLoaded(this.items);

  @override
  final List<ComboboxModel> items;

  @override
  List<Object?> get props => [items];
}

final class ComboboxFailure extends ComboboxState {
  const ComboboxFailure({required this.message, this.items = const []});

  final String message;

  @override
  final List<ComboboxModel> items;

  @override
  List<Object?> get props => [message, items];
}
