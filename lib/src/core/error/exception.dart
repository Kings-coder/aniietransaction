import 'package:equatable/equatable.dart';

class ServerException extends Equatable implements Exception {
  final String message;
  final int statusCode;
  const ServerException({required this.message, required this.statusCode});
  @override
  List<Object?> get props => [message, statusCode];
}

class CacheException extends Equatable implements Exception {
  final String message;
  
  const CacheException({required this.message});
  @override
  List<Object?> get props => [message];
}

class NetworkException extends Equatable implements Exception {
  final String message;
  const NetworkException({required this.message});
  @override
  List<Object?> get props => [message];
}

class UnknownException extends Equatable implements Exception {
  final String message;
  const UnknownException({required this.message});
  @override
  List<Object?> get props => [message];
}

class BadRequestException extends Equatable implements Exception {
  final String message;
  const BadRequestException({required this.message});
  @override
  List<Object?> get props => [message];
}

class APIException extends ServerException {
  const APIException({required super.message, required super.statusCode});

  @override
  String toString() {
    return message;
  }
  
}

class CacheFailure extends CacheException {
  const CacheFailure({required super.message});

  @override
  String toString() {
    return message;
  }
}
class RouteException implements Exception {
  final String message;
  const RouteException(this.message);
}
class NetworkFailure extends NetworkException {
  const NetworkFailure({required super.message});

  @override
  String toString() {
    return message;
  }
}
class UnknownFailure extends UnknownException {
  const UnknownFailure({required super.message});

  @override
  String toString() {
    return message;
  }
}
class BadRequestFailure extends BadRequestException {
  const BadRequestFailure({required super.message});

  @override
  String toString() {
    return message;
  }
}