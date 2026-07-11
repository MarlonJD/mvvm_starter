/// Environment-derived runtime configuration for public network examples.
final class AppConfig {
  factory AppConfig({
    required Uri restPostsUri,
    required Uri graphqlUri,
    required Duration requestTimeout,
  }) {
    _validateEndpoint(restPostsUri, "REST_POSTS_URL");
    _validateEndpoint(graphqlUri, "GRAPHQL_URL");
    if (requestTimeout <= Duration.zero) {
      throw ArgumentError.value(
        requestTimeout,
        "requestTimeout",
        "must be positive",
      );
    }
    return AppConfig._(
      restPostsUri: restPostsUri,
      graphqlUri: graphqlUri,
      requestTimeout: requestTimeout,
    );
  }

  const AppConfig._({
    required this.restPostsUri,
    required this.graphqlUri,
    required this.requestTimeout,
  });

  /// Reads public endpoint settings from compile-time environment values.
  factory AppConfig.fromEnvironment() {
    return AppConfig(
      restPostsUri: Uri.parse(
        const String.fromEnvironment(
          "REST_POSTS_URL",
          defaultValue: "https://jsonplaceholder.typicode.com/posts",
        ),
      ),
      graphqlUri: Uri.parse(
        const String.fromEnvironment(
          "GRAPHQL_URL",
          defaultValue: "https://countries.trevorblades.com/",
        ),
      ),
      requestTimeout: const Duration(seconds: 15),
    );
  }

  /// REST posts endpoint.
  final Uri restPostsUri;

  /// GraphQL endpoint.
  final Uri graphqlUri;

  /// Per-request timeout applied by the shared executor.
  final Duration requestTimeout;

  static void _validateEndpoint(Uri uri, String settingName) {
    final localhost =
        uri.host == "localhost" || uri.host == "127.0.0.1" || uri.host == "::1";
    final allowedScheme =
        uri.scheme == "https" ||
        (localhost && (uri.scheme == "http" || uri.scheme == "https"));
    if (!uri.hasAuthority || !allowedScheme) {
      throw ArgumentError.value(
        uri,
        settingName,
        "must use HTTPS (HTTP is allowed only for localhost tests)",
      );
    }
  }
}
