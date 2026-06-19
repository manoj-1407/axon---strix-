class AppException implements Exception {
  final String message;
  final String? code;
  const AppException(this.message, {this.code});

  @override
  String toString() => 'AppException: $message';
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});
}

class TimeoutException extends AppException {
  const TimeoutException(super.message, {super.code});
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

class RateLimitException extends AppException {
  final int? retryAfterSeconds;
  const RateLimitException(super.message,
      {super.code, this.retryAfterSeconds});
}

class InvalidResponseException extends AppException {
  const InvalidResponseException(super.message, {super.code});
}

class LocalStorageException extends AppException {
  const LocalStorageException(super.message, {super.code});
}

class ServerException extends AppException {
  final int statusCode;
  const ServerException(super.message,
      {super.code, required this.statusCode});
}
