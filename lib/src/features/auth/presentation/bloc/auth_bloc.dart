import 'package:bloc/bloc.dart';
import 'package:bs_mobile/src/features/auth/models/auth_model.dart';
import 'package:bs_mobile/src/features/auth/repository/auth_repository.dart';
import 'package:equatable/equatable.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthInitial()) {
    on<AuthLoginEvent>(_onLogin);
    on<AuthLogoutEvent>(_onLogout);
  }

  Future<void> _onLogin(AuthLoginEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _authRepository.login(event.req!);
    if (result.messageCode == '0') {
      emit(AuthSuccess(authResponseModel: result));
    } else {
      emit(AuthFailure(result.messageText));
    }
  }

  Future<void> _onLogout(AuthLogoutEvent event, Emitter<AuthState> emit) async {
    emit(const AuthInitial());
    final success = await _authRepository.logout();
    if (success.messageCode == '0') {
      emit(AuthLogout(authResponseModel: success));
    } else {
      emit(AuthFailure(success.messageText));
    }
  }
}
