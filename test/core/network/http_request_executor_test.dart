import "dart:async";
import "dart:convert";

import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:mvvm_starter/app/app_config.dart";
import "package:mvvm_starter/core/network/authorization_header_provider.dart";
import "package:mvvm_starter/core/network/graphql_request_executor.dart";
import "package:mvvm_starter/core/network/http_request_executor.dart";
import "package:mvvm_starter/core/network/network_exception.dart";
import "package:mvvm_starter/core/result/result.dart";

void main() {
  group("AppConfig", () {
    test("accepts HTTPS endpoints and localhost test endpoints", () {
      expect(
        () => AppConfig(
          restPostsUri: Uri.parse("https://example.com/posts"),
          graphqlUri: Uri.parse("http://localhost/graphql"),
          requestTimeout: const Duration(seconds: 1),
        ),
        returnsNormally,
      );
    });

    test("rejects non-HTTPS non-localhost endpoints", () {
      expect(
        () => AppConfig(
          restPostsUri: Uri.parse("http://example.com/posts"),
          graphqlUri: Uri.parse("https://example.com/graphql"),
          requestTimeout: const Duration(seconds: 1),
        ),
        throwsArgumentError,
      );
    });
  });

  group("HttpRequestExecutor", () {
    test("times out every request using the injected duration", () async {
      final executor = HttpRequestExecutor(
        client: MockClient((_) => Completer<http.Response>().future),
        timeout: const Duration(milliseconds: 1),
      );

      await expectLater(
        executor.get(Uri.parse("https://example.com/posts")),
        throwsA(
          isA<NetworkException>().having(
            (error) => error.kind,
            "kind",
            NetworkExceptionKind.timeout,
          ),
        ),
      );
    });

    for (final entry in {
      400: NetworkExceptionKind.badRequest,
      401: NetworkExceptionKind.unauthorized,
      403: NetworkExceptionKind.forbidden,
      429: NetworkExceptionKind.rateLimited,
      500: NetworkExceptionKind.server,
    }.entries) {
      test("maps HTTP ${entry.key} to ${entry.value.name}", () async {
        final executor = HttpRequestExecutor(
          client: MockClient((_) async => http.Response("", entry.key)),
          timeout: const Duration(seconds: 1),
        );

        await expectLater(
          executor.get(Uri.parse("https://example.com/posts")),
          throwsA(
            isA<NetworkException>().having(
              (error) => error.kind,
              "kind",
              entry.value,
            ),
          ),
        );
      });
    }

    test("sends no Authorization header without a provider", () async {
      http.Request? captured;
      final executor = HttpRequestExecutor(
        client: MockClient((request) async {
          captured = request;
          return http.Response("[]", 200);
        }),
        timeout: const Duration(seconds: 1),
      );

      await executor.get(Uri.parse("https://example.com/posts"));

      expect(captured!.headers, isNot(contains("authorization")));
    });

    test("one 401 forces one refresh and one REST replay", () async {
      final requests = <http.Request>[];
      final provider = _FakeAuthorizationHeaderProvider();
      final executor = HttpRequestExecutor(
        client: MockClient((request) async {
          requests.add(request);
          return http.Response("[]", requests.length == 1 ? 401 : 200);
        }),
        timeout: const Duration(seconds: 1),
        authorizationHeaderProvider: provider,
      );

      await executor.get(Uri.parse("https://example.com/posts"));

      expect(provider.forceRefreshValues, [false, true]);
      expect(requests.map((request) => request.headers["authorization"]), [
        "Bearer old-token",
        "Bearer new-token",
      ]);
    });

    test("a second 401 is not replayed again", () async {
      var requestCount = 0;
      final provider = _FakeAuthorizationHeaderProvider();
      final executor = HttpRequestExecutor(
        client: MockClient((_) async {
          requestCount += 1;
          return http.Response("", 401);
        }),
        timeout: const Duration(seconds: 1),
        authorizationHeaderProvider: provider,
      );

      await expectLater(
        executor.get(Uri.parse("https://example.com/posts")),
        throwsA(
          isA<NetworkException>().having(
            (error) => error.kind,
            "kind",
            NetworkExceptionKind.unauthorized,
          ),
        ),
      );
      expect(requestCount, 2);
      expect(provider.forceRefreshValues, [false, true]);
    });
  });

  group("HttpGraphqlRequestExecutor", () {
    test("serializes variables and optional operation name", () async {
      http.Request? captured;
      final httpExecutor = HttpRequestExecutor(
        client: MockClient((request) async {
          captured = request;
          return http.Response('{"data":{"country":{"code":"TR"}}}', 200);
        }),
        timeout: const Duration(seconds: 1),
      );
      final executor = HttpGraphqlRequestExecutor(httpExecutor);

      final data = await executor.execute(
        uri: Uri.parse("https://example.com/graphql"),
        document:
            r"query Country($code: ID!) { country(code: $code) { code } }",
        variables: const {"code": "TR"},
        operationName: "Country",
      );

      expect(jsonDecode(captured!.body), {
        "query": r"query Country($code: ID!) { country(code: $code) { code } }",
        "variables": {"code": "TR"},
        "operationName": "Country",
      });
      expect(data, {
        "country": {"code": "TR"},
      });
    });

    test("rejects a non-empty GraphQL errors list even with data", () async {
      final httpExecutor = HttpRequestExecutor(
        client: MockClient(
          (_) async => http.Response(
            '{"data":{"countries":[]},"errors":[{"message":"no"}]}',
            200,
          ),
        ),
        timeout: const Duration(seconds: 1),
      );
      final executor = HttpGraphqlRequestExecutor(httpExecutor);

      await expectLater(
        executor.execute(
          uri: Uri.parse("https://example.com/graphql"),
          document: "query Countries { countries { code } }",
        ),
        throwsA(
          isA<NetworkException>().having(
            (error) => error.kind,
            "kind",
            NetworkExceptionKind.graphql,
          ),
        ),
      );
    });

    test("rejects a non-object GraphQL response", () async {
      final httpExecutor = HttpRequestExecutor(
        client: MockClient((_) async => http.Response("[]", 200)),
        timeout: const Duration(seconds: 1),
      );
      final executor = HttpGraphqlRequestExecutor(httpExecutor);

      await expectLater(
        executor.execute(
          uri: Uri.parse("https://example.com/graphql"),
          document: "query Countries { countries { code } }",
        ),
        throwsA(
          isA<NetworkException>().having(
            (error) => error.kind,
            "kind",
            NetworkExceptionKind.invalidPayload,
          ),
        ),
      );
    });

    test("one 401 forces one refresh and one GraphQL replay", () async {
      final requests = <http.Request>[];
      final provider = _FakeAuthorizationHeaderProvider();
      final httpExecutor = HttpRequestExecutor(
        client: MockClient((request) async {
          requests.add(request);
          return requests.length == 1
              ? http.Response("", 401)
              : http.Response('{"data":{"countries":[]}}', 200);
        }),
        timeout: const Duration(seconds: 1),
        authorizationHeaderProvider: provider,
      );
      final executor = HttpGraphqlRequestExecutor(httpExecutor);

      await executor.execute(
        uri: Uri.parse("https://example.com/graphql"),
        document: "query Countries { countries { code } }",
      );

      expect(provider.forceRefreshValues, [false, true]);
      expect(requests.map((request) => request.headers["authorization"]), [
        "Bearer old-token",
        "Bearer new-token",
      ]);
    });
  });
}

final class _FakeAuthorizationHeaderProvider
    implements AuthorizationHeaderProvider {
  final List<bool> forceRefreshValues = [];

  @override
  Future<Result<String?>> authorizationHeader({
    bool forceRefresh = false,
  }) async {
    forceRefreshValues.add(forceRefresh);
    return Result.success(
      forceRefresh ? "Bearer new-token" : "Bearer old-token",
    );
  }
}
