import "package:flutter/material.dart";
import "package:mvvm_starter/auth/user.dart";
import "package:mvvm_starter/auth/user_service.dart";

class HomeViewModel {
  HomeViewModel({required UserService userService})
      : _userService = userService;

  final UserService _userService;

  ValueNotifier<User?> get userNotifier => _userService.userNotifier;

  void deleteAllUsers() {
    _userService
      ..deleteSession(userNotifier.value!)
      ..deleteAllUsers();
  }

  void logout() {
    _userService.deleteSession(userNotifier.value!);
  }
}
