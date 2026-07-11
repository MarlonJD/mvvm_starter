import "package:easy_localization/easy_localization.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:mvvm_starter/app/routes.dart";
import "package:mvvm_starter/core/errors/app_error.dart";
import "package:mvvm_starter/core/restoration/restoration_registrar.dart";
import "package:mvvm_starter/features/auth/presentation/login_view_model.dart";

/// Stable key for the login name input.
const loginNameFieldKey = Key("login-name-field");

/// Stable key for the login button.
const loginButtonKey = Key("login-button");

/// Login screen.
final class LoginView extends StatefulWidget {
  /// Creates a login screen.
  const LoginView({required this.viewModel, super.key});

  /// ViewModel for this screen.
  final LoginViewModel viewModel;

  @override
  State<LoginView> createState() => _LoginViewState();
}

final class _LoginViewState extends State<LoginView> with RestorationMixin {
  LoginViewModel get viewModel => widget.viewModel;

  @override
  String? get restorationId => "login_view";

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    viewModel.registerRestorableProperties(MixinRestorationRegistrar(this));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("auth.login.title".tr()),
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: "debug.database.title".tr(),
              onPressed: () {
                context.pushNamed(AppRoute.debugDatabase.name);
              },
              icon: const Icon(Icons.storage_outlined),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            spacing: 12,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: loginNameFieldKey,
                controller: viewModel.nameController.value,
                decoration: InputDecoration(labelText: "auth.name.label".tr()),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _login(context),
              ),
              SizedBox(
                width: double.infinity,
                child: ValueListenableBuilder(
                  valueListenable: viewModel.state,
                  builder: (context, state, child) {
                    return ElevatedButton(
                      key: loginButtonKey,
                      onPressed: state.isLoading ? null : () => _login(context),
                      child: state.isLoading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text("auth.login.button".tr()),
                    );
                  },
                ),
              ),
              TextButton(
                onPressed: () {
                  context.pushNamed(AppRoute.signup.name);
                },
                child: Text("auth.signup.cta".tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _login(BuildContext context) async {
    final result = await viewModel.login();
    final error = result.errorOrNull;
    if (error != null) {
      _showSnackBar(context, error);
      return;
    }
    viewModel.nameController.value.clear();
    context.goNamed(AppRoute.home.name);
  }

  void _showSnackBar(BuildContext context, AppError error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.messageKey.tr())));
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }
}
