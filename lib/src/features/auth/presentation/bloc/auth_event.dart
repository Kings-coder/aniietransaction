part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object> get props => [];
}

class LoginEvent extends AuthEvent {
  final DataMap data;
  const LoginEvent(this.data);
  @override
  List<Object> get props => [data];
}

class RegisterEvent extends AuthEvent {
  final DataMap data;
  const RegisterEvent(this.data);
  @override
  List<Object> get props => [data];
}

class LogoutEvent extends AuthEvent {}

class CheckAuthEvent extends AuthEvent {}
