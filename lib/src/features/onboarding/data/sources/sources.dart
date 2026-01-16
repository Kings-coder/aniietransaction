 
    import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/exception.dart';
    
        abstract interface class OnboardingLocalDataSource {
      const OnboardingLocalDataSource();
      Future<void> cacheFirstTimer();
      Future<bool> checkIfUserIsFirstTimer();
    }

    const kFirstTimerKey = 'firstTimer';

    class OnboardingLocalDataSourceImpl implements OnboardingLocalDataSource {
     //
      OnboardingLocalDataSourceImpl();
  final SharedPreferences sharedPreferences = SharedPreferences.getInstance() as SharedPreferences;
      @override
      Future<void> cacheFirstTimer() async {
       try {
        await sharedPreferences.setBool(kFirstTimerKey, false);
       } catch (e) {
        throw CacheException(message: e.toString());
       }
      }

      @override
      Future<bool> checkIfUserIsFirstTimer() async {
        try {
          final result = sharedPreferences.getBool(kFirstTimerKey) ?? true;
          return result;
        } catch (e) {
          throw CacheException(message: e.toString());
        }
      }
    }