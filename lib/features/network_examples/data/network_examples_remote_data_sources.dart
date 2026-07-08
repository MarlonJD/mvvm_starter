import "dart:convert";

import "package:http/http.dart" as http;
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

/// HTTP implementation backed by JSONPlaceholder.
final class HttpRestPostsRemoteDataSource implements RestPostsRemoteDataSource {
  /// Creates a REST posts remote source.
  const HttpRestPostsRemoteDataSource({required http.Client client})
      : _client = client;

  final http.Client _client;

  static final Uri _postsUri = Uri.https(
    "jsonplaceholder.typicode.com",
    "/posts",
  );

  @override
  Future<List<RestPost>> fetchPosts({int limit = 5}) async {
    final uri = _postsUri.replace(queryParameters: {"_limit": "$limit"});
    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException(
        "REST request failed with status ${response.statusCode}",
        uri,
      );
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .cast<Map<String, dynamic>>()
        .map(
          (item) => RestPost(
            id: item["id"] as int,
            userId: item["userId"] as int,
            title: item["title"] as String,
            body: item["body"] as String,
          ),
        )
        .toList();
  }
}

/// HTTP implementation backed by the public Countries GraphQL API.
final class HttpGraphqlCountriesRemoteDataSource
    implements GraphqlCountriesRemoteDataSource {
  /// Creates a GraphQL countries remote source.
  const HttpGraphqlCountriesRemoteDataSource({required http.Client client})
      : _client = client;

  final http.Client _client;

  static final Uri _countriesUri = Uri.https("countries.trevorblades.com", "/");

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
    final response = await _client.post(
      _countriesUri,
      headers: const {"Content-Type": "application/json"},
      body: jsonEncode({"query": _countriesQuery}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException(
        "GraphQL request failed with status ${response.statusCode}",
        _countriesUri,
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final errors = decoded["errors"];
    if (errors is List && errors.isNotEmpty) {
      throw FormatException("GraphQL returned errors", errors);
    }

    final data = decoded["data"] as Map<String, dynamic>;
    final countries = data["countries"] as List<dynamic>;
    return countries
        .cast<Map<String, dynamic>>()
        .take(limit)
        .map(
          (item) => GraphqlCountry(
            code: item["code"] as String,
            name: item["name"] as String,
            emoji: item["emoji"] as String,
            capital: item["capital"] as String?,
          ),
        )
        .toList();
  }
}
