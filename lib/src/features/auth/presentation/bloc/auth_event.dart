part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class AuthLoginEvent extends AuthEvent {
  const AuthLoginEvent(this.req);

  final AuthLoginRequest? req;

  @override
  List<Object?> get props => [req];
}

final class AuthLogoutEvent extends AuthEvent {
  const AuthLogoutEvent();
}
