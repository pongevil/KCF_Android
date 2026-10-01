part of 'menu_bloc.dart';

sealed class MenuState extends Equatable {
  const MenuState();

  @override
  List<Object?> get props => [];
}

final class MenuInitial extends MenuState {
  const MenuInitial();
}

final class MenuLoading extends MenuState {
  const MenuLoading();
}

final class MenuSuccess extends MenuState {
  const MenuSuccess({this.menuItems});

  final MenuResponse? menuItems;

  @override
  List<Object?> get props => [menuItems];
}

final class MenuFailure extends MenuState {
  const MenuFailure({required this.error});

  final String error;

  @override
  List<Object?> get props => [error];
}
