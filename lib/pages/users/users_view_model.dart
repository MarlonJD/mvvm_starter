import "package:flutter/foundation.dart";
import "package:mvvm_starter/auth/user.dart";
import "package:mvvm_starter/auth/user_service.dart";

class UsersViewModel {
  UsersViewModel({
    required UserService userService,
  }) : _userService = userService;

  final UserService _userService;

  ValueNotifier<List<User>> get usersNotifier => ValueNotifier([]);

  void getAllUsers() {
    usersNotifier.value = [
      User(id: 1, name: "Test User", uid: "test-uid", isAdmin: 0),
      User(id: 2, name: "Test User 2", uid: "test-uid-2", isAdmin: 0),
    ];
  }

  void deleteAllUsers() {
    _userService.deleteAllUsers();
  }

  void deleteUser(User user) {
    _userService.deleteUser(user);
  }
}
