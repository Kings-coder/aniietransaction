import 'package:bloctutorial/src/core/types/typedefs.dart';
import 'package:bloctutorial/src/core/usecases/usecases.dart';

import '../repositories/repositories.dart';

class CacheFirstTimer implements UsecaseWithoutParams<void> {
  final OnboardingRepository repository;

  CacheFirstTimer(this.repository);

  @override
  ResultFuture<void> call() async => repository.cacheFirstTimer();
}
