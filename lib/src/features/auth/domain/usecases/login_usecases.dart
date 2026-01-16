
import '../../../../core/types/typedefs.dart';
import '../../../../core/usecases/usecases.dart';
import '../repositories/authRepositories.dart';

class UserLoginUsecase implements UsecaseWithParams<void, DataMap> {
  final AuthRepository _repository;
  UserLoginUsecase(this._repository);
  
  @override
  ResultFuture<void> call(DataMap params)async =>
     _repository.signInWithCredentials(params);
  
}