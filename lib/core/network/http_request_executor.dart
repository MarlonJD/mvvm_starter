import "dart:async";
import "dart:convert";
import "dart:io";

import "package:http/http.dart" as http;
import "package:mvvm_starter/core/errors/app_error.dart";
import "package:mvvm_starter/core/network/authorization_header_provider.dart";
import "package:mvvm_starter/core/network/network_exception.dart";

/// Shared timeout-bounded executor for REST and GraphQL HTTP requests.
final class HttpRequestExecutor {
  /// Creates an HTTP executor.
  const HttpRequestExecutor({
    required this.client,
    required this.timeout,
    this.authorizationHeaderProvider,
  });

  /// Shared HTTP client.
  final http.Client client;

  /// Timeout applied to every request attempt.
  final Duration timeout;

  /// Optional bearer/header source.
  final AuthorizationHeaderProvider? authorizationHeaderProvider;

  /// Executes a GET request.
  Future<http.Response> get(Uri uri) {
    return _execute(
      context: "GET ${uri.host}${uri.path}",
      send: (headers) => client.get(uri, headers: headers),
    );
  }

  /// Executes a JSON POST request.
  Future<http.Response> postJson(Uri uri, Object? body) {
    return _execute(
      context: "POST ${uri.host}${uri.path}",
      send: (headers) => client.post(
        uri,
        headers: {"Content-Type": "application/json", ...headers},
        body: jsonEncode(body),
      ),
    );
  }

  Future<http.Response> _execute({
    required String context,
    required Future<http.Response> Function(Map<String, String> headers) send,
  }) async {
    var response = await _sendAttempt(
      context: context,
      forceRefresh: false,
      send: send,
    );
    if (response.statusCode == HttpStatus.unauthorized &&
        authorizationHeaderProvider != null) {
      response = await _sendAttempt(
        context: context,
        forceRefresh: true,
        send: send,
      );
    }
    _throwForStatus(response.statusCode, context);
    return response;
  }

  Future<http.Response> _sendAttempt({
    required String context,
    required bool forceRefresh,
    required Future<http.Response> Function(Map<String, String> headers) send,
  }) async {
    final headers = <String, String>{};
    final provider = authorizationHeaderProvider;
    if (provider != null) {
      final result = await provider.authorizationHeader(
        forceRefresh: forceRefresh,
      );
      final value = result.valueOrNull;
      final error = result.errorOrNull;
      if (error != null) {
        if (error.type == AppErrorType.unauthorized) {
          throw NetworkException(
            kind: NetworkExceptionKind.unauthorized,
            context: "authorization.header",
            cause: error,
          );
        }
        throw NetworkException.transport("authorization.header", cause: error);
      }
      if (value != null && value.isNotEmpty) {
        headers[HttpHeaders.authorizationHeader] = value;
      }
    }

    try {
      return await send(headers).timeout(timeout);
    } on NetworkException {
      rethrow;
    } on TimeoutException {
      throw NetworkException.timeout(context);
    } on http.ClientException catch (error) {
      throw NetworkException.transport(context, cause: error);
    } on SocketException catch (error) {
      throw NetworkException.transport(context, cause: error);
    } on Exception catch (error) {
      throw NetworkException.transport(context, cause: error);
    }
  }

  void _throwForStatus(int statusCode, String context) {
    if (statusCode >= HttpStatus.ok &&
        statusCode < HttpStatus.multipleChoices) {
      return;
    }
    final kind = switch (statusCode) {
      HttpStatus.badRequest => NetworkExceptionKind.badRequest,
      HttpStatus.unauthorized => NetworkExceptionKind.unauthorized,
      HttpStatus.forbidden => NetworkExceptionKind.forbidden,
      HttpStatus.tooManyRequests => NetworkExceptionKind.rateLimited,
      >= HttpStatus.internalServerError => NetworkExceptionKind.server,
      >= HttpStatus.badRequest => NetworkExceptionKind.badRequest,
      _ => NetworkExceptionKind.transport,
    };
    throw NetworkException(
      kind: kind,
      context: context,
      statusCode: statusCode,
    );
  }
}
