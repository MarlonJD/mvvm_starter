import "package:flutter/foundation.dart";

/// REST post returned by the public JSONPlaceholder example API.
@immutable
final class RestPost {
  /// Creates a REST post.
  const RestPost({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  /// Remote post id.
  final int id;

  /// Remote user id.
  final int userId;

  /// Post title.
  final String title;

  /// Post body.
  final String body;

  @override
  bool operator ==(Object other) {
    return other is RestPost &&
        other.id == id &&
        other.userId == userId &&
        other.title == title &&
        other.body == body;
  }

  @override
  int get hashCode => Object.hash(id, userId, title, body);
}

/// GraphQL country returned by the public Countries example API.
@immutable
final class GraphqlCountry {
  /// Creates a GraphQL country.
  const GraphqlCountry({
    required this.code,
    required this.name,
    required this.emoji,
    required this.capital,
  });

  /// ISO country code.
  final String code;

  /// Country display name.
  final String name;

  /// Emoji returned by the public GraphQL API.
  final String emoji;

  /// Capital, when available.
  final String? capital;

  @override
  bool operator ==(Object other) {
    return other is GraphqlCountry &&
        other.code == code &&
        other.name == name &&
        other.emoji == emoji &&
        other.capital == capital;
  }

  @override
  int get hashCode => Object.hash(code, name, emoji, capital);
}
