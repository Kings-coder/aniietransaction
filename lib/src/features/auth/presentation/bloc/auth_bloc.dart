import 'package:bloctutorial/src/features/auth/data/implements/auth_repository_impl.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/types/typedefs.dart';
import '../../data/models/models.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<LoginEvent>(_authLoginEvent);
  }

  final _repo = AuthRepositoryImp();

  Future<void> _authLoginEvent(
    LoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final result = await _repo.signInWithCredentials(event.data);
      result.fold(
        (failure) => emit(AuthFailure(message: failure.message)),
        (result) => emit(AuthSuccess(user: result.$1, message: result.$2)),
      );
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }
}
