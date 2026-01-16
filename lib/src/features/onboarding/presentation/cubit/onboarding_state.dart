part of 'onboarding_cubit.dart';

abstract class OnboardingState extends Equatable {
  const OnboardingState([this.index = 0]);
  final int index;
  @override
  List<Object> get props => [];
}

class OnboardingInitial extends OnboardingState {
  const OnboardingInitial();
}

class OnboardingLoading extends OnboardingState {
  const OnboardingLoading();
}

class CacheFirstTimerSuccess extends OnboardingState {
  const CacheFirstTimerSuccess();
}

class OnboardingPageState extends OnboardingState {
  const OnboardingPageState(super.index);
}

class CheckingIfUserIsFirstTime extends OnboardingState {
  const CheckingIfUserIsFirstTime();
}

class UserCached extends OnboardingState {
  const UserCached();
}

class UserNotCached extends OnboardingState {
  const UserNotCached();
}

class OnboardingError extends OnboardingState {
  final String message;
  const OnboardingError(this.message);
  @override
  List<Object> get props => [message];
}

class OnboardingStatus extends OnboardingState {
  final bool isFirstTime;
  const OnboardingStatus({required this.isFirstTime});
  @override
  List<Object> get props => [isFirstTime];
}
