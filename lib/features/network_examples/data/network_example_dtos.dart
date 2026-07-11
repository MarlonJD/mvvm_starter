import "package:mvvm_starter/core/network/network_exception.dart";
import "package:mvvm_starter/features/network_examples/domain/network_example_models.dart";

/// Validated REST post payload.
final class RestPostDto {
  /// Creates a REST post DTO.
  const RestPostDto({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  /// Parses and validates a REST payload object.
  factory RestPostDto.fromJson(Object? value) {
    final json = _object(value, "rest.item");
    return RestPostDto(
      id: _integer(json, "id", "rest.id"),
      userId: _integer(json, "userId", "rest.userId"),
      title: _string(json, "title", "rest.title"),
      body: _string(json, "body", "rest.body"),
    );
  }

  /// Remote post id.
  final int id;

  /// Remote user id.
  final int userId;

  /// Post title.
  final String title;

  /// Post body.
  final String body;

  /// Maps this DTO into the feature domain model.
  RestPost toDomain() {
    return RestPost(id: id, userId: userId, title: title, body: body);
  }
}

/// Validated GraphQL country payload.
final class GraphqlCountryDto {
  /// Creates a country DTO.
  const GraphqlCountryDto({
    required this.code,
    required this.name,
    required this.emoji,
    required this.capital,
  });

  /// Parses and validates a GraphQL country object.
  factory GraphqlCountryDto.fromJson(Object? value) {
    final json = _object(value, "graphql.country");
    final capital = json["capital"];
    if (capital != null && capital is! String) {
      throw const NetworkException.invalidPayload("graphql.capital");
    }
    return GraphqlCountryDto(
      code: _string(json, "code", "graphql.code"),
      name: _string(json, "name", "graphql.name"),
      emoji: _string(json, "emoji", "graphql.emoji"),
      capital: capital as String?,
    );
  }

  /// ISO country code.
  final String code;

  /// Country display name.
  final String name;

  /// Country emoji.
  final String emoji;

  /// Country capital, when available.
  final String? capital;

  /// Maps this DTO into the feature domain model.
  GraphqlCountry toDomain() {
    return GraphqlCountry(
      code: code,
      name: name,
      emoji: emoji,
      capital: capital,
    );
  }
}

Map<String, Object?> _object(Object? value, String context) {
  if (value is! Map<String, Object?>) {
    throw NetworkException.invalidPayload(context);
  }
  return value;
}

int _integer(Map<String, Object?> json, String key, String context) {
  final value = json[key];
  if (value is! int) {
    throw NetworkException.invalidPayload(context);
  }
  return value;
}

String _string(Map<String, Object?> json, String key, String context) {
  final value = json[key];
  if (value is! String) {
    throw NetworkException.invalidPayload(context);
  }
  return value;
}
