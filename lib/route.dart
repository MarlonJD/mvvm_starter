// ignore_for_file: public_member_api_docs, sort_constructors_first
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:mvvm_starter/auth/login_view.dart";
import "package:mvvm_starter/auth/user_service.dart";
import "package:mvvm_starter/pages/home/home_view.dart";

class RouterService {
  RouterService({
    required userService,
  }) : _userService = userService;

  final UserService _userService;

  late final GoRouter _router = GoRouter(
    routes: <GoRoute>[
      GoRoute(
        path: "/",
        builder: (BuildContext context, GoRouterState state) =>
            const HomeView(),
      ),
      GoRoute(
        path: "/login",
        builder: (BuildContext context, GoRouterState state) =>
            const LoginView(),
      ),
    ],
    refreshListenable: _userService.userNotifier,
    // redirect to the login page if the user is not logged in
    redirect: (BuildContext context, GoRouterState state) async {
      // Using `of` method creates a dependency of StreamAuthScope. It will
      // cause go_router to reparse current route if StreamAuth has new sign-in
      // information.
      final loggedIn = _userService.isLoggedIn();
      final loggingIn = state.matchedLocation == "/login";
      if (!loggedIn) {
        debugPrint("Redirecting to /login");
        return "/login";
      }

      // if the user is logged in but still on the login page, send them to
      // the home page
      if (loggingIn) {
        debugPrint("Redirecting to /");
        return "/";
      }

      // no need to redirect at all
      return null;
    },
  );

  GoRouter get router => _router;
}
