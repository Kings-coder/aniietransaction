
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/types/typedefs.dart';
import '../../domain/repositories/repositories.dart';
import '../sources/sources.dart';

class OnBoardingRepositoryImpl implements OnboardingRepository {
  final OnboardingLocalDataSource _localDataSource;
  OnBoardingRepositoryImpl(this._localDataSource);

  @override
  ResultFuture<void> cacheFirstTimer() async {
  try {
     await _localDataSource.cacheFirstTimer();
    return Right(null);
  } on CacheFailure catch (e) {
    return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
  }
  }

@override
  ResultFuture<bool> checkIfUserIsFirstTimer() async {
  try {
    final result= await _localDataSource.checkIfUserIsFirstTimer();
    return Right(result);
  } on CacheFailure catch (e) {
    return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
  }
}
}