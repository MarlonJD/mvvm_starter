/// Local starter user.
final class User {
  /// Creates a user domain object.
  const User({
    required this.id,
    required this.uid,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Database id.
  final int id;

  /// Stable local uid.
  final String uid;

  /// Login/display name.
  final String name;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last update timestamp.
  final DateTime updatedAt;
}
