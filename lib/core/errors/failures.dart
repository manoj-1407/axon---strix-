import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

class TimeoutFailure extends Failure {
  const TimeoutFailure(super.message, {super.code});
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

class RateLimitFailure extends Failure {
  final int? retryAfterSeconds;
  const RateLimitFailure(super.message,
      {super.code, this.retryAfterSeconds});
}

class InvalidResponseFailure extends Failure {
  const InvalidResponseFailure(super.message, {super.code});
}

class LocalStorageFailure extends Failure {
  const LocalStorageFailure(super.message, {super.code});
}

class ProviderNotConfiguredFailure extends Failure {
  const ProviderNotConfiguredFailure(super.message, {super.code});
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {super.code, this.statusCode});
}

class OfflineFailure extends Failure {
  const OfflineFailure(super.message, {super.code});
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.code});
}
