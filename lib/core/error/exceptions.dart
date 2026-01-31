/// Base exception class for the application
abstract class AppException implements Exception {
  const AppException({required this.message, this.code, this.stackTrace});

  final String message;
  final String? code;
  final StackTrace? stackTrace;

  @override
  String toString() => 'AppException: $message (code: $code)';
}

/// Exception thrown when a server error occurs
class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.code,
    super.stackTrace,
    this.statusCode,
  });

  final int? statusCode;

  @override
  String toString() => 'ServerException: $message (statusCode: $statusCode)';
}

/// Exception thrown when a cache/local storage error occurs
class CacheException extends AppException {
  const CacheException({required super.message, super.code, super.stackTrace});

  @override
  String toString() => 'CacheException: $message';
}

/// Exception thrown when a network error occurs
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code,
    super.stackTrace,
  });

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception thrown when authentication fails
class AuthException extends AppException {
  const AuthException({required super.message, super.code, super.stackTrace});

  @override
  String toString() => 'AuthException: $message';
}

/// Exception thrown when validation fails
class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.code,
    super.stackTrace,
    this.fieldErrors,
  });

  final Map<String, List<String>>? fieldErrors;

  @override
  String toString() => 'ValidationException: $message';
}

/// Exception thrown when a resource is not found
class NotFoundException extends AppException {
  const NotFoundException({
    required super.message,
    super.code,
    super.stackTrace,
  });

  @override
  String toString() => 'NotFoundException: $message';
}

/// Exception thrown when permission is denied
class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    super.code,
    super.stackTrace,
  });

  @override
  String toString() => 'PermissionException: $message';
}
