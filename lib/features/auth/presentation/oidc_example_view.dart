import "dart:async";

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:mvvm_starter/app/routes.dart";
import "package:mvvm_starter/features/auth/presentation/oidc_example_view_model.dart";

/// Native OIDC example screen that never renders raw tokens.
final class OidcExampleView extends StatefulWidget {
  /// Creates an OIDC example view.
  const OidcExampleView({required this.viewModel, super.key});

  /// ViewModel for this screen.
  final OidcExampleViewModel viewModel;

  @override
  State<OidcExampleView> createState() => _OidcExampleViewState();
}

final class _OidcExampleViewState extends State<OidcExampleView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("auth.oidc.title".tr())),
      body: ValueListenableBuilder<OidcExampleState>(
        valueListenable: widget.viewModel.state,
        builder: (context, state, child) {
          final busy = switch (state.status) {
            OidcExampleStatus.signingIn ||
            OidcExampleStatus.refreshing ||
            OidcExampleStatus.signingOut => true,
            _ => false,
          };
          final messageKey = switch (state.status) {
            OidcExampleStatus.unconfigured => "auth.oidc.notConfigured",
            OidcExampleStatus.unsupported => "auth.oidc.unsupportedPlatform",
            OidcExampleStatus.signedOut => "auth.oidc.signedOut",
            OidcExampleStatus.signingIn => "auth.oidc.signingIn",
            OidcExampleStatus.signedIn => "auth.oidc.signedIn",
            OidcExampleStatus.refreshing => "auth.oidc.refreshing",
            OidcExampleStatus.signingOut => "auth.oidc.signingOut",
            OidcExampleStatus.warning =>
              state.error?.messageKey ?? "auth.oidc.operationFailed",
          };
          final canUseProvider =
              state.status != OidcExampleStatus.unconfigured &&
              state.status != OidcExampleStatus.unsupported;
          final signedIn = state.status == OidcExampleStatus.signedIn;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (busy) const CircularProgressIndicator(),
                  if (busy) const SizedBox(height: 16),
                  Text(
                    messageKey.tr(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  if (canUseProvider && !signedIn && !busy)
                    FilledButton(
                      onPressed: () => unawaited(widget.viewModel.signIn()),
                      child: Text("auth.oidc.signIn".tr()),
                    ),
                  if (signedIn && !busy) ...[
                    FilledButton.tonal(
                      onPressed: () => unawaited(widget.viewModel.refresh()),
                      child: Text("auth.oidc.refresh".tr()),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => unawaited(widget.viewModel.logout()),
                      child: Text("auth.oidc.logout".tr()),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      context.goNamed(AppRoute.networkExamples.name);
                    },
                    child: Text("auth.oidc.backToNetworkExamples".tr()),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    widget.viewModel.dispose();
    super.dispose();
  }
}
