import "package:flutter/material.dart";
import "package:mvvm_starter/auth/user.dart";
import "package:mvvm_starter/auth/user_service.dart";

class LoginViewModel {
  LoginViewModel({required UserService userService})
      : _userService = userService;

  final UserService _userService;

  ValueNotifier<User?> get userNotifier => _userService.userNotifier;

  User? login(String name) {
    try {
      return _userService.createSession(name);
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      return null;
    }
  }
}
