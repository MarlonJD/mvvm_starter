import "package:drift/drift.dart";
import "package:mvvm_starter/core/database/app_database.dart";
import "package:mvvm_starter/features/auth/domain/user.dart";

/// Local Drift-backed auth data source.
final class AuthLocalDataSource {
  /// Creates an auth local data source.
  AuthLocalDataSource(this._database);

  final AppDatabase _database;

  /// Creates a user and makes it the active session.
  Future<User> createUserAndSession({
    required String uid,
    required String name,
    required bool isAdmin,
    required DateTime now,
  }) {
    return _database.transaction(() async {
      final id = await _database.into(_database.users).insert(
            UsersCompanion.insert(
              uid: uid,
              name: name,
              isAdmin: Value(isAdmin),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await replaceSession(userId: id, now: now);
      final user = await findUserById(id);
      if (user == null) {
        throw StateError("Created user was not found.");
      }
      return user;
    });
  }

  /// Finds a user by id.
  Future<User?> findUserById(int id) async {
    final query = _database.select(_database.users)
      ..where((row) => row.id.equals(id));
    final row = await query.getSingleOrNull();
    return row?.toDomain();
  }

  /// Finds a user by login name.
  Future<User?> findUserByName(String name) async {
    final query = _database.select(_database.users)
      ..where((row) => row.name.equals(name));
    final row = await query.getSingleOrNull();
    return row?.toDomain();
  }

  /// Returns the active session user.
  Future<User?> activeUser() async {
    final session =
        await _database.select(_database.appSessions).getSingleOrNull();
    if (session == null) {
      return null;
    }
    return findUserById(session.userId);
  }

  /// Watches the active session user.
  Stream<User?> watchActiveUser() {
    final query = _database.select(_database.appSessions).join(
      [
        innerJoin(
          _database.users,
          _database.users.id.equalsExp(_database.appSessions.userId),
        ),
      ],
    );

    return query.watchSingleOrNull().map((row) {
      return row?.readTable(_database.users).toDomain();
    });
  }

  /// Replaces the singleton active session.
  Future<void> replaceSession({
    required int userId,
    required DateTime now,
  }) {
    return _database.transaction(() async {
      await _database.delete(_database.appSessions).go();
      await _database.into(_database.appSessions).insert(
            AppSessionsCompanion.insert(
              id: 1,
              userId: userId,
              createdAt: now,
              updatedAt: now,
            ),
          );
    });
  }

  /// Clears the active session.
  Future<void> clearSession() async {
    await _database.delete(_database.appSessions).go();
  }

  /// Deletes one user.
  Future<void> deleteUser(User user) async {
    await (_database.delete(_database.users)
          ..where((row) => row.id.equals(user.id)))
        .go();
  }

  /// Deletes all users and sessions.
  Future<void> deleteAllUsers() {
    return _database.transaction(() async {
      await _database.delete(_database.appSessions).go();
      await _database.delete(_database.users).go();
    });
  }

  /// Returns all users.
  Future<List<User>> users() async {
    final rows = await (_database.select(_database.users)
          ..orderBy([(row) => OrderingTerm.asc(row.id)]))
        .get();
    return rows.map((row) => row.toDomain()).toList();
  }

  /// Watches all users.
  Stream<List<User>> watchUsers() {
    return (_database.select(_database.users)
          ..orderBy([(row) => OrderingTerm.asc(row.id)]))
        .watch()
        .map((rows) => rows.map((row) => row.toDomain()).toList());
  }

  /// Returns active session user ids.
  Future<List<int>> sessionUserIds() async {
    final rows = await _database.select(_database.appSessions).get();
    return rows.map((row) => row.userId).toList();
  }

  /// Watches active session user ids.
  Stream<List<int>> watchSessionUserIds() {
    return _database
        .select(_database.appSessions)
        .watch()
        .map((rows) => rows.map((row) => row.userId).toList());
  }
}

extension on UserRow {
  User toDomain() {
    return User(
      id: id,
      uid: uid,
      name: name,
      isAdmin: isAdmin,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
