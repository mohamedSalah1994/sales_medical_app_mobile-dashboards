class Failure {
  Failure(this.message);

  final String message;
}

class ServerFailure extends Failure {
  ServerFailure({required String message}) : super(message);
}

class NetworkFailure extends Failure {
  NetworkFailure({required String message}) : super(message);
}
