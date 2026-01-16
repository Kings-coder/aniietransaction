import 'package:bloctutorial/src/core/types/typedefs.dart';
import 'package:bloctutorial/src/features/auth/data/models/models.dart';

import '../../../../core/error/exception.dart';
import '../../../../core/services/rest_api_service.dart';

abstract interface class AuthRemoteDataSource {
 // Future<void> signUp(DataMap data);
  Future<(UserModel, String)> signInWithCredentials(DataMap data);
}

class AuthRemoteDataSourceImp implements AuthRemoteDataSource {
  AuthRemoteDataSourceImp();

  final _apiService = RestApiService();
  static const _timeout = 20;

  @override

  Future<(UserModel, String)> signInWithCredentials(DataMap data) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/login',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        data: data,
        timeoutSeconds: _timeout,
      );
      String token;
      String expiresIn;
      try {
        token = response.body['token'] as String;
        expiresIn = response.body['expiresIn'] as String;
      } catch (e) {
        throw APIException(message: "User is unauthorized", statusCode: 515);
      }
      final user = UserModel.fromJson(response.body['data'] as Map<String, dynamic>);
      return (user, token);
    } catch (e) {
      throw APIException(message: e.toString(), statusCode: 515);
    }
  }
}
