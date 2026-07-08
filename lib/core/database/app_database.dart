import "package:drift/drift.dart";
import "package:mvvm_starter/core/database/app_database_connection.dart";
import "package:mvvm_starter/core/database/migrations.dart";

part "app_database.g.dart";

/// Users table for local auth examples.
@DataClassName("UserRow")
class Users extends Table {
  /// Primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Stable local uid.
  TextColumn get uid => text().unique()();

  /// Unique display/login name.
  TextColumn get name => text().unique()();

  /// Example admin flag.
  BoolColumn get isAdmin => boolean()
      .named("is_admin")
      .customConstraint("NOT NULL DEFAULT 0 CHECK (is_admin IN (0, 1))")();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().named("created_at")();

  /// Last update timestamp.
  DateTimeColumn get updatedAt => dateTime().named("updated_at")();
}

/// Singleton active app session table.
@DataClassName("AppSessionRow")
class AppSessions extends Table {
  /// Singleton primary key, always 1.
  IntColumn get id => integer().customConstraint("NOT NULL CHECK (id = 1)")();

  /// Active user id.
  IntColumn get userId => integer()
      .named("user_id")
      .unique()
      .references(Users, #id, onDelete: KeyAction.cascade)();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().named("created_at")();

  /// Last update timestamp.
  DateTimeColumn get updatedAt => dateTime().named("updated_at")();
}

/// Drift database for app/domain data.
@DriftDatabase(tables: [Users, AppSessions])
class AppDatabase extends _$AppDatabase {
  /// Opens the database with [executor].
  AppDatabase(super.executor);

  /// Opens the default application database.
  AppDatabase.defaults() : super(openAppDatabaseConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => appMigrationStrategy(this);
}
