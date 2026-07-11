import "dart:convert";

import "package:mvvm_starter/core/network/graphql_request_executor.dart";
import "package:mvvm_starter/core/network/http_request_executor.dart";
import "package:mvvm_starter/core/network/network_exception.dart";
import "package:mvvm_starter/features/network_examples/data/network_example_dtos.dart";
import "package:mvvm_starter/features/network_examples/domain/network_example_models.dart";

/// Remote REST source for example posts.
abstract interface class RestPostsRemoteDataSource {
  /// Fetches posts from the remote source.
  Future<List<RestPost>> fetchPosts({int limit = 5});
}

/// Remote GraphQL source for example countries.
abstract interface class GraphqlCountriesRemoteDataSource {
  /// Fetches countries from the remote source.
  Future<List<GraphqlCountry>> fetchCountries({int limit = 6});
}

/// HTTP implementation backed by a configurable REST endpoint.
final class HttpRestPostsRemoteDataSource implements RestPostsRemoteDataSource {
  /// Creates a REST posts remote source.
  const HttpRestPostsRemoteDataSource({
    required this.executor,
    required this.postsUri,
  });

  /// Shared typed HTTP executor.
  final HttpRequestExecutor executor;

  /// Configured posts endpoint.
  final Uri postsUri;

  @override
  Future<List<RestPost>> fetchPosts({int limit = 5}) async {
    final uri = postsUri.replace(
      queryParameters: {...postsUri.queryParameters, "_limit": "$limit"},
    );
    final response = await executor.get(uri);

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException catch (error) {
      throw NetworkException.invalidPayload("rest.envelope", cause: error);
    }
    if (decoded is! List<Object?>) {
      throw const NetworkException.invalidPayload("rest.envelope");
    }
    return decoded
        .map(RestPostDto.fromJson)
        .map((dto) => dto.toDomain())
        .toList();
  }
}

/// HTTP implementation backed by a configurable GraphQL endpoint.
final class HttpGraphqlCountriesRemoteDataSource
    implements GraphqlCountriesRemoteDataSource {
  /// Creates a GraphQL countries remote source.
  const HttpGraphqlCountriesRemoteDataSource({
    required this.executor,
    required this.graphqlUri,
  });

  /// Shared GraphQL executor.
  final GraphqlRequestExecutor executor;

  /// Configured GraphQL endpoint.
  final Uri graphqlUri;

  static const String _countriesQuery = """
    query Countries {
      countries {
        code
        name
        emoji
        capital
      }
    }
  """;

  @override
  Future<List<GraphqlCountry>> fetchCountries({int limit = 6}) async {
    final data = await executor.execute(
      uri: graphqlUri,
      document: _countriesQuery,
      operationName: "Countries",
    );
    final countries = data["countries"];
    if (countries is! List<Object?>) {
      throw const NetworkException.invalidPayload("graphql.countries");
    }
    return countries
        .take(limit)
        .map(GraphqlCountryDto.fromJson)
        .map((dto) => dto.toDomain())
        .toList();
  }
}
