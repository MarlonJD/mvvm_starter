import "package:flutter/foundation.dart";
import "package:flutter/widgets.dart";
import "package:go_router/go_router.dart";
import "package:mvvm_starter/app/routes.dart";
import "package:mvvm_starter/features/auth/data/auth_repository.dart";

/// Route widget builder.
typedef AppRouteWidgetBuilder = Widget Function(
  BuildContext context,
  GoRouterState state,
);

/// App router composition service.
final class RouterService {
  /// Creates the app router.
  RouterService({
    required AuthRepository authRepository,
    required AppRouteWidgetBuilder homeBuilder,
    required AppRouteWidgetBuilder networkExamplesBuilder,
    required AppRouteWidgetBuilder loginBuilder,
    required AppRouteWidgetBuilder signupBuilder,
    required AppRouteWidgetBuilder debugDatabaseBuilder,
  })  : _authRepository = authRepository,
        _homeBuilder = homeBuilder,
        _networkExamplesBuilder = networkExamplesBuilder,
        _loginBuilder = loginBuilder,
        _signupBuilder = signupBuilder,
        _debugDatabaseBuilder = debugDatabaseBuilder;

  final AuthRepository _authRepository;
  final AppRouteWidgetBuilder _homeBuilder;
  final AppRouteWidgetBuilder _networkExamplesBuilder;
  final AppRouteWidgetBuilder _loginBuilder;
  final AppRouteWidgetBuilder _signupBuilder;
  final AppRouteWidgetBuilder _debugDatabaseBuilder;

  late final GoRouter _router = GoRouter(
    initialLocation: AppRoute.home.path,
    refreshListenable: _authRepository.activeUser,
    routes: [
      GoRoute(
        name: AppRoute.home.name,
        path: AppRoute.home.path,
        builder: _homeBuilder,
      ),
      GoRoute(
        name: AppRoute.networkExamples.name,
        path: AppRoute.networkExamples.path,
        builder: _networkExamplesBuilder,
      ),
      GoRoute(
        name: AppRoute.login.name,
        path: AppRoute.login.path,
        builder: _loginBuilder,
      ),
      GoRoute(
        name: AppRoute.signup.name,
        path: AppRoute.signup.path,
        builder: _signupBuilder,
      ),
      if (kDebugMode)
        GoRoute(
          name: AppRoute.debugDatabase.name,
          path: AppRoute.debugDatabase.path,
          builder: _debugDatabaseBuilder,
        ),
    ],
    redirect: (context, state) {
      final loggedIn = _authRepository.isLoggedIn;
      final isAuthRoute = state.matchedLocation == AppRoute.login.path ||
          state.matchedLocation == AppRoute.signup.path;

      if (!loggedIn && !isAuthRoute) {
        return AppRoute.login.path;
      }
      if (loggedIn && isAuthRoute) {
        return AppRoute.home.path;
      }
      return null;
    },
  );

  /// Configured go_router instance.
  GoRouter get router => _router;

  /// Releases router resources.
  void dispose() {
    _router.dispose();
  }
}
