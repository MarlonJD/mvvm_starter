import "dart:convert";

import "package:mvvm_starter/core/network/http_request_executor.dart";
import "package:mvvm_starter/core/network/network_exception.dart";

/// Executes a GraphQL document and returns its validated data object.
abstract interface class GraphqlRequestExecutor {
  /// Sends a GraphQL request.
  Future<Map<String, Object?>> execute({
    required Uri uri,
    required String document,
    Map<String, Object?> variables = const {},
    String? operationName,
  });
}

/// GraphQL executor backed by the shared typed HTTP executor.
final class HttpGraphqlRequestExecutor implements GraphqlRequestExecutor {
  /// Creates a GraphQL executor.
  const HttpGraphqlRequestExecutor(this._http);

  final HttpRequestExecutor _http;

  @override
  Future<Map<String, Object?>> execute({
    required Uri uri,
    required String document,
    Map<String, Object?> variables = const {},
    String? operationName,
  }) async {
    final body = <String, Object?>{
      "query": document,
      "variables": variables,
      "operationName": ?operationName,
    };
    final response = await _http.postJson(uri, body);

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException catch (error) {
      throw NetworkException.invalidPayload("graphql.envelope", cause: error);
    }
    if (decoded is! Map<String, Object?>) {
      throw const NetworkException.invalidPayload("graphql.envelope");
    }
    final errors = decoded["errors"];
    if (errors is List<Object?> && errors.isNotEmpty) {
      throw const NetworkException.graphql();
    }
    final data = decoded["data"];
    if (data is! Map<String, Object?>) {
      throw const NetworkException.invalidPayload("graphql.data");
    }
    return Map<String, Object?>.from(data);
  }
}
