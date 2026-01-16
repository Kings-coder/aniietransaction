import 'package:bloctutorial/src/core/types/typedefs.dart';

import '../entities/users.dart';

abstract interface class AuthRepository {
  ResultVoid signUp(DataMap data);
  ResultFuture<(UserEntity, String)> signInWithCredentials(DataMap data);
}
