import 'package:equatable/equatable.dart';

/// Base failure class for the application
/// Failures are used in the domain layer to represent errors
/// They are immutable and use Equatable for value equality
abstract class Failure extends Equatable {
  const Failure({required this.message, this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}

/// Failure representing a server error
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code, this.statusCode});

  final int? statusCode;

  @override
  List<Object?> get props => [message, code, statusCode];
}

/// Failure representing a cache/local storage error
class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}

/// Failure representing a network connectivity error
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code});
}

/// Failure representing an authentication error
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}

/// Failure representing a validation error
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code,
    this.fieldErrors,
  });

  final Map<String, List<String>>? fieldErrors;

  @override
  List<Object?> get props => [message, code, fieldErrors];
}

/// Failure representing a not found error
class NotFoundFailure extends Failure {
  const NotFoundFailure({required super.message, super.code});
}

/// Failure representing a permission denied error
class PermissionFailure extends Failure {
  const PermissionFailure({required super.message, super.code});
}

/// Failure representing an unexpected error
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({required super.message, super.code});
}
