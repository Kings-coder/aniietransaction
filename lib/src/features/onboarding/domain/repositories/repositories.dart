 
    import '../../../../core/types/typedefs.dart';

abstract interface class OnboardingRepository {
       const OnboardingRepository();
       ResultFuture<bool> checkIfUserIsFirstTimer();
       ResultFuture<void> cacheFirstTimer();
      }
    