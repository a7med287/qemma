/// Base class for all expected (handled) failures across the app.
///
/// Repositories should return `Either<Failure, T>` (or similar) instead of
/// throwing, so the presentation layer can always show a friendly message.
abstract class Failure {
  const Failure(this.message);
  final String message;
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode});

  final int? statusCode;
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}
