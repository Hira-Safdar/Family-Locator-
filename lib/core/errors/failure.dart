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

class FirestoreFailure extends Failure{
  const FirestoreFailure(super.message);
}

class GroupNotFoundFailure extends Failure{
  const GroupNotFoundFailure(super.message);
}

class GroupAlreadyMemberFailure extends Failure{
  const GroupAlreadyMemberFailure(super.message);
}

