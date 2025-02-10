import "package:mvvm_starter/auth/user.dart";
import "package:mvvm_starter/auth/user_service.dart";
import "package:uuid/uuid.dart";

class SignupViewModel {
  SignupViewModel(UserService userService) : _userService = userService;

  final UserService _userService;

  User? createUser(String name) {
    try {
      if (name == "admin") {
        return _userService.createUser(
          User(
            name: name,
            uid: const Uuid().v4(),
            isAdmin: 1,
          ),
        );
      } else {
        return _userService.createUser(
          User(
            name: name,
            uid: const Uuid().v4(),
            isAdmin: 0,
          ),
        );
      }
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      return null;
    }
  }
}
