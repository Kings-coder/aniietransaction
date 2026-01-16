// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:bloctutorial/src/core/error/exception.dart';
import 'package:bloctutorial/src/core/error/failures.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/types/typedefs.dart';
import '../../domain/repositories/authRepositories.dart';
import '../models/models.dart';
import '../sources/sources.dart';

class AuthRepositoryImp implements AuthRepository {
  AuthRepositoryImp();
  final _remoteDataSource = AuthRemoteDataSourceImp();
  @override
 ResultFuture<(UserModel, String)> signInWithCredentials(
      DataMap data,) async {
    try {
      final result = await _remoteDataSource.signInWithCredentials(data);
      return Right(result);
    } on APIException catch (e) {
      return Left(ApiFailure.fromException( e));
    }
  }

  @override
  ResultFuture<(UserModel, String)> signUp(DataMap data) {
    throw UnimplementedError();
  }
}
