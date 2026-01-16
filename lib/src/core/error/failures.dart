import 'package:equatable/equatable.dart';

import 'exception.dart';

class Failure extends Equatable {
  final String message;
  final int statusCode;
  const Failure({required this.message, required this.statusCode});

String get errorMessage => message;

  @override
  List<Object> get props => [message, statusCode];
}
class CacheFailure extends Failure {
  const CacheFailure({required super.message, required super.statusCode});
}

class ApiFailure extends Failure {
  const ApiFailure({required super.message, required super.statusCode});
  ApiFailure.fromException(APIException exception)
      : super(message: exception.message, statusCode: exception.statusCode);
}