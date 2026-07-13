import "package:easy_localization/easy_localization.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:mvvm_starter/app/routes.dart";
import "package:mvvm_starter/core/errors/app_error.dart";
import "package:mvvm_starter/core/restoration/restoration_registrar.dart";
import "package:mvvm_starter/features/auth/presentation/signup_view_model.dart";

/// Stable key for the signup name input.
const signupNameFieldKey = Key("signup-name-field");

/// Stable key for the signup button.
const signupButtonKey = Key("signup-button");

/// Signup screen.
final class SignupView extends StatefulWidget {
  /// Creates a signup screen.
  const SignupView({required this.viewModel, super.key});

  /// ViewModel for this screen.
  final SignupViewModel viewModel;

  @override
  State<SignupView> createState() => _SignupViewState();
}

final class _SignupViewState extends State<SignupView> with RestorationMixin {
  SignupViewModel get viewModel => widget.viewModel;

  @override
  String? get restorationId => "signup_view";

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    viewModel.registerRestorableProperties(MixinRestorationRegistrar(this));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("auth.signup.title".tr()),
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
                key: signupNameFieldKey,
                controller: viewModel.nameController.value,
                decoration: InputDecoration(labelText: "auth.name.label".tr()),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _createUser(context),
              ),
              SizedBox(
                width: double.infinity,
                child: ValueListenableBuilder(
                  valueListenable: viewModel.state,
                  builder: (context, state, child) {
                    return ElevatedButton(
                      key: signupButtonKey,
                      onPressed: state.isLoading
                          ? null
                          : () => _createUser(context),
                      child: state.isLoading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text("auth.signup.button".tr()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createUser(BuildContext context) async {
    final result = await viewModel.createUser();
    if (!context.mounted) {
      return;
    }
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
