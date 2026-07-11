/// Central app route definitions.
enum AppRoute {
  /// Authenticated home route.
  home("/"),

  /// Network examples route.
  networkExamples("/network-examples"),

  /// Native OIDC example route.
  oidcExample("/auth/oidc-example"),

  /// Login route.
  login("/login"),

  /// Signup route.
  signup("/signup"),

  /// Debug database route.
  debugDatabase("/debug/database");

  const AppRoute(this.path);

  /// URL path for the route.
  final String path;
}
