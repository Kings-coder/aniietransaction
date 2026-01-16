import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/catchfirsttime_usecases.dart';
import '../../domain/usecases/check_if_user_is_first_timer.dart';

part 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  final CacheFirstTimer _cacheFirstTimer;
  final CheckIfUserIsFirstTimer _checkIfUserIsFirstTimer;

  OnboardingCubit({
    required CacheFirstTimer cacheFirstTimer,
    required CheckIfUserIsFirstTimer checkIfUserIsFirstTimer,
  })  : _cacheFirstTimer = cacheFirstTimer,
        _checkIfUserIsFirstTimer = checkIfUserIsFirstTimer,
        super(OnboardingInitial());

  Future<void> cacheFirstTimer() async {
    emit(CacheFirstTimerSuccess());
    final result = await _cacheFirstTimer();
    result.fold(
      (l) => emit(OnboardingError(l.errorMessage)),
      (_) => emit(UserCached()),
    );
  }

  Future<void> checkIfUserIsFirstTimer() async {
    emit(CheckingIfUserIsFirstTime());
    final result = await _checkIfUserIsFirstTimer();
    result.fold(
      (l) => emit(OnboardingStatus(isFirstTime: true)),
      (r) => emit(OnboardingStatus(isFirstTime: r)),
    );
  }
}
