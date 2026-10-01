part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthSuccess extends AuthState {
  const AuthSuccess({this.authResponseModel});

  final AuthLoginResponse? authResponseModel;

  @override
  List<Object?> get props => [authResponseModel];
}

final class AuthFailure extends AuthState {
  const AuthFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class AuthLogout extends AuthState {
  const AuthLogout({this.authResponseModel});

  final AuthLoginResponse? authResponseModel;

  @override
  List<Object?> get props => [authResponseModel];
}
