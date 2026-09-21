abstract class Failure{
  final String message;
  const Failure(this.message);
}

class AuthFailure extends Failure{
  const AuthFailure(super.message);

}

class NetworkFailure extends Failure{
  const NetworkFailure(super.message);
  }