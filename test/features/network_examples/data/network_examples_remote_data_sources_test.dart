import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";
import "package:mvvm_starter/app/app_config.dart";
import "package:mvvm_starter/core/network/graphql_request_executor.dart";
import "package:mvvm_starter/core/network/http_request_executor.dart";
import "package:mvvm_starter/core/network/network_exception.dart";
import "package:mvvm_starter/features/network_examples/data/network_examples_remote_data_sources.dart";
import "package:mvvm_starter/features/network_examples/domain/network_example_models.dart";

void main() {
  late AppConfig config;

  setUp(() {
    config = AppConfig(
      restPostsUri: Uri.parse(
        "http://localhost:8080/custom-posts?fixture=true",
      ),
      graphqlUri: Uri.parse("http://localhost:8080/custom-graphql"),
      requestTimeout: const Duration(seconds: 1),
    );
  });

  test("REST endpoint and query parameters come from AppConfig", () async {
    Uri? capturedUri;
    final executor = HttpRequestExecutor(
      client: MockClient((request) async {
        capturedUri = request.url;
        return http.Response(
          '[{"id":7,"userId":2,"title":"Title","body":"Body"}]',
          200,
        );
      }),
      timeout: config.requestTimeout,
    );
    final source = HttpRestPostsRemoteDataSource(
      executor: executor,
      postsUri: config.restPostsUri,
    );

    final posts = await source.fetchPosts(limit: 3);

    expect(capturedUri!.path, "/custom-posts");
    expect(capturedUri!.queryParameters, {"fixture": "true", "_limit": "3"});
    expect(posts, const [
      RestPost(id: 7, userId: 2, title: "Title", body: "Body"),
    ]);
  });

  test("malformed REST JSON maps to invalidPayload", () async {
    final executor = HttpRequestExecutor(
      client: MockClient((_) async => http.Response('{"id":"bad"}', 200)),
      timeout: config.requestTimeout,
    );
    final source = HttpRestPostsRemoteDataSource(
      executor: executor,
      postsUri: config.restPostsUri,
    );

    await expectLater(
      source.fetchPosts(),
      throwsA(
        isA<NetworkException>().having(
          (error) => error.kind,
          "kind",
          NetworkExceptionKind.invalidPayload,
        ),
      ),
    );
  });

  test(
    "GraphQL endpoint comes from AppConfig and decodes typed countries",
    () async {
      Uri? capturedUri;
      final httpExecutor = HttpRequestExecutor(
        client: MockClient((request) async {
          capturedUri = request.url;
          return http.Response(
            '{"data":{"countries":[{"code":"TR","name":"Turkey","emoji":"TR","capital":"Ankara"}]}}',
            200,
          );
        }),
        timeout: config.requestTimeout,
      );
      final source = HttpGraphqlCountriesRemoteDataSource(
        executor: HttpGraphqlRequestExecutor(httpExecutor),
        graphqlUri: config.graphqlUri,
      );

      final countries = await source.fetchCountries(limit: 1);

      expect(capturedUri, config.graphqlUri);
      expect(countries, const [
        GraphqlCountry(
          code: "TR",
          name: "Turkey",
          emoji: "TR",
          capital: "Ankara",
        ),
      ]);
    },
  );
}
