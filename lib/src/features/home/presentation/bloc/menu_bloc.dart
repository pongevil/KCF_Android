import 'package:bs_mobile/src/features/home/models/menu_response_model.dart';
import 'package:bs_mobile/src/features/home/repository/menu_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'menu_event.dart';
part 'menu_state.dart';

class MenuBloc extends Bloc<MenuEvent, MenuState> {
  final MenuRepository _menuRepository;

  MenuBloc(MenuRepository menuRepository)
    : _menuRepository = menuRepository,
      super(const MenuInitial()) {
    on<FetchMenuEvent>(_fetchMenu);
  }

  Future<void> _fetchMenu(FetchMenuEvent event, Emitter<MenuState> emit) async {
    emit(const MenuLoading());
    final result = await _menuRepository.fetchMenu();
    if (result.messageCode == '0') {
      emit(MenuSuccess(menuItems: result));
    } else {
      emit(MenuFailure(error: result.messageText ?? 'Failed to fetch menu'));
    }
  }
}
