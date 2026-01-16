import '../../../../core/types/typedefs.dart';
import '../../../../core/usecases/usecases.dart';
import '../repositories/authRepositories.dart';

class RegisterUsecases implements UsecaseWithParams<void, DataMap> {
  final AuthRepository _repository;
  RegisterUsecases(this._repository);
  @override
  ResultFuture<void> call(DataMap params) {
    return _repository.signUp(params);
  }
}
