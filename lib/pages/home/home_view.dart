import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:mvvm_starter/auth/user_service.dart";
import "package:mvvm_starter/core/database_view.dart";
import "package:mvvm_starter/core/locator.dart";
import "package:mvvm_starter/pages/home/home_view_model.dart";

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final HomeViewModel homeViewModel = HomeViewModel(
    userService: locator<UserService>(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Home"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DatabasePage(),
                ),
              );
            },
            child: const Text("Show Database"),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder(
              valueListenable: homeViewModel.userNotifier,
              builder: (context, user, child) {
                return Text(
                  "Welcome, {}".tr(
                    args: [
                      "${user?.name}",
                    ],
                  ),
                  style: Theme.of(context).textTheme.headlineLarge,
                );
              },
            ),
            if (homeViewModel.userNotifier.value?.isAdmin == 1)
              TextButton(
                onPressed: () {
                  homeViewModel.deleteAllUsers();
                },
                child: const Text("Delete All Users"),
              ),
            TextButton(
              onPressed: () {
                homeViewModel.logout();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Logged out"),
                  ),
                );
              },
              child: const Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }
}
