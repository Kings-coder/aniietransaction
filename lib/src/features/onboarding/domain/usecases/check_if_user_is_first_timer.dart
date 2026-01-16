import 'package:bloctutorial/src/core/types/typedefs.dart';

import '../../../../core/usecases/usecases.dart';
import '../repositories/repositories.dart';

class CheckIfUserIsFirstTimer implements UsecaseWithoutParams<bool> {
  final OnboardingRepository _repository;
  CheckIfUserIsFirstTimer(this._repository);
  @override
  ResultFuture<bool> call() async => _repository.checkIfUserIsFirstTimer();
}
