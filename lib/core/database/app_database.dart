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

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// REST posts persisted by the network examples feature.
@DataClassName("RestPostRow")
class RestPosts extends Table {
  /// Remote post id.
  IntColumn get id => integer()();

  /// Remote user id for the post.
  IntColumn get userId => integer().named("user_id")();

  /// Post title.
  TextColumn get title => text()();

  /// Post body.
  TextColumn get body => text()();

  /// Last network fetch timestamp.
  DateTimeColumn get fetchedAt => dateTime().named("fetched_at")();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// GraphQL countries persisted by the network examples feature.
@DataClassName("GraphqlCountryRow")
class GraphqlCountries extends Table {
  /// ISO country code.
  TextColumn get code => text()();

  /// Country display name.
  TextColumn get name => text()();

  /// Country emoji returned by the public GraphQL example API.
  TextColumn get emoji => text()();

  /// Country capital, if the API exposes one.
  TextColumn get capital => text().nullable()();

  /// Last network fetch timestamp.
  DateTimeColumn get fetchedAt => dateTime().named("fetched_at")();

  @override
  Set<Column<Object>> get primaryKey => {code};
}

/// Drift database for app/domain data.
@DriftDatabase(tables: [Users, AppSessions, RestPosts, GraphqlCountries])
class AppDatabase extends _$AppDatabase {
  /// Opens the database with [executor].
  AppDatabase(super.executor);

  /// Opens the default application database.
  AppDatabase.defaults() : super(openAppDatabaseConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => appMigrationStrategy(this);
}
