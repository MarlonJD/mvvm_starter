import "package:easy_localization/easy_localization.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:mvvm_starter/app/routes.dart";
import "package:mvvm_starter/features/auth/domain/user.dart";
import "package:mvvm_starter/features/home/presentation/home_view_model.dart";

/// Stable key for the logout button.
const logoutButtonKey = Key("logout-button");

/// Home screen.
final class HomeView extends StatelessWidget {
  /// Creates a home screen.
  const HomeView({required this.viewModel, super.key});

  /// ViewModel for this screen.
  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("home.title".tr()),
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: "debug.database.title".tr(),
              onPressed: () {
                context.pushNamed(AppRoute.debugDatabase.name);
              },
              icon: const Icon(Icons.storage_outlined),
            ),
          IconButton(
            tooltip: "networkExamples.title".tr(),
            onPressed: () {
              context.pushNamed(AppRoute.networkExamples.name);
            },
            icon: const Icon(Icons.cloud_sync_outlined),
          ),
        ],
      ),
      body: Center(
        child: ValueListenableBuilder<User?>(
          valueListenable: viewModel.activeUser,
          builder: (context, user, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "home.welcome".tr(args: [user?.name ?? ""]),
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                TextButton(
                  key: logoutButtonKey,
                  onPressed: () async {
                    final result = await viewModel.logout();
                    if (!context.mounted) {
                      return;
                    }
                    final error = result.errorOrNull;
                    if (error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error.messageKey.tr())),
                      );
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("home.loggedOut".tr())),
                    );
                    context.goNamed(AppRoute.login.name);
                  },
                  child: Text("home.logout".tr()),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
