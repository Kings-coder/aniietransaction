
    import '../sources/sources.dart';
    import '../../domain/repositories/repositories.dart';
    
    class SplashRepositoryImp implements SplashRepository{

        final SplashRemoteDataSource remoteDataSource;
        SplashRepositoryImp({required this.remoteDataSource});
      
        // ... example ...
        //
        // Future<User> getUser(String userId) async {
        //     return remoteDataSource.getUser(userId);
        //   }
        // ...
    }
    