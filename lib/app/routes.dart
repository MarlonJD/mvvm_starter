/// Central app route definitions.
enum AppRoute {
  /// Authenticated home route.
  home("/"),

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
