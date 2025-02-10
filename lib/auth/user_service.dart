import "dart:async";

import "package:flutter/foundation.dart";
import "package:mvvm_starter/auth/user.dart";
import "package:mvvm_starter/core/database_abstract.dart";

class UserService {
  UserService({required DatabaseAbstraction databaseAbstraction})
      : _databaseAbstraction = databaseAbstraction;

  final DatabaseAbstraction _databaseAbstraction;

  final ValueNotifier<User?> userNotifier = ValueNotifier(null);

  StreamSubscription<User?>? userStreamSubscription;

  /// Creates a user and returns the created user
  ///
  /// Throws: [Exception]
  ///
  /// * [Exception] - If the user is not found
  User createUser(User user) {
    const query = "INSERT INTO users (name, uid, admin) VALUES (?, ?, ?)";
    _databaseAbstraction.dbExecute(query, [user.name, user.uid, user.isAdmin]);
    final dbUser = getUser(user.name);
    if (dbUser == null) {
      throw Exception("User not found");
    }
    _createSession(dbUser);
    return dbUser;
  }

  /// Delete any session for this user as well
  void deleteUser(User user) {
    deleteSession(user);

    const deleteUserQuery = "DELETE FROM users WHERE id = ?";
    _databaseAbstraction.dbExecute(deleteUserQuery, [user.id]);
  }

  /// Delete all users
  void deleteAllUsers() {
    const deleteUsersQuery = "DELETE FROM users";
    _databaseAbstraction.dbExecute(deleteUsersQuery);
  }

  /// Creates a session for a user and returns the user
  ///
  /// Throws: [Exception]
  ///
  /// * [Exception] - If the user is not found
  User? createSession(String name) {
    final user = getUser(name);
    if (user == null) {
      throw Exception("User not found");
    }

    _createSession(user);
    return user;
  }

  User? sessionExists() {
    const query = "SELECT * FROM sessions";
    final result = _databaseAbstraction.dbSelect(query);
    if (result.isEmpty) {
      return null;
    }

    final sessionUserId = result[0]["user_id"] as int;
    const userQuery = "SELECT * FROM users WHERE id = ?";
    final userResult =
        _databaseAbstraction.dbSelect(userQuery, [sessionUserId]);
    final user = User.fromJson(userResult[0]);
    _listenToUser(user);
    userNotifier.value = user;
    return user;
  }

  void deleteSession(User user) {
    const query = "DELETE FROM sessions WHERE user_id = ?";
    _databaseAbstraction.dbExecute(query, [user.id]);
    userNotifier.value = null;
  }

  User? getUser(String name) {
    const query = "SELECT * FROM users WHERE name = ?";
    final result = _databaseAbstraction.dbSelect(query, [name]);
    return result.map(User.fromJson).firstOrNull;
  }

  void _listenToUser(User user) {
    // Cancel existing subscription first
    userStreamSubscription?.cancel();

    userStreamSubscription = _databaseAbstraction.dbUpdates
        .where((update) => update.tableName == "users")
        .map((_) {
      const query = "SELECT * FROM users WHERE name = ?";
      final result = _databaseAbstraction.dbSelect(query, [user.name]);
      final userResult = result.map(User.fromJson).firstOrNull;
      return userResult;
    }).listen((userResult) {
      userNotifier.value = userResult;
    });
  }

  void _createSession(User user) {
    deleteSession(user);
    const insertQuery = "INSERT INTO sessions (user_id) VALUES (?)";
    _databaseAbstraction.dbExecute(insertQuery, [user.id]);
    _listenToUser(user);
    userNotifier.value = user;
  }
}
