import "dart:async";

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:mvvm_starter/core/result/ui_state.dart";
import "package:mvvm_starter/features/network_examples/domain/network_example_models.dart";
import "package:mvvm_starter/features/network_examples/presentation/network_examples_view_model.dart";

/// Network examples screen.
final class NetworkExamplesView extends StatefulWidget {
  /// Creates a network examples screen.
  const NetworkExamplesView({required this.viewModel, super.key});

  /// ViewModel for this screen.
  final NetworkExamplesViewModel viewModel;

  @override
  State<NetworkExamplesView> createState() => _NetworkExamplesViewState();
}

final class _NetworkExamplesViewState extends State<NetworkExamplesView> {
  NetworkExamplesViewModel get viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    unawaited(viewModel.load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("networkExamples.title".tr()),
        actions: [
          IconButton(
            tooltip: "networkExamples.refresh".tr(),
            onPressed: () {
              unawaited(viewModel.load());
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ValueListenableBuilder<UiState<NetworkExamplesState>>(
        valueListenable: viewModel.state,
        builder: (context, state, child) {
          return switch (state) {
            UiIdle<NetworkExamplesState>() => const SizedBox.shrink(),
            UiLoading<NetworkExamplesState>() => const Center(
                child: CircularProgressIndicator(),
              ),
            UiFailure<NetworkExamplesState>(:final error) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(error.messageKey.tr()),
                ),
              ),
            UiSuccess<NetworkExamplesState>(:final value) =>
              _NetworkExamplesContent(state: value),
          };
        },
      ),
    );
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }
}

final class _NetworkExamplesContent extends StatelessWidget {
  const _NetworkExamplesContent({
    required this.state,
  });

  final NetworkExamplesState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _RestPostsSection(
          title: "networkExamples.restRemoteOnly.title".tr(),
          subtitle: "networkExamples.restRemoteOnly.subtitle".tr(),
          posts: state.restRemoteOnly,
        ),
        const SizedBox(height: 16),
        _RestPostsSection(
          title: "networkExamples.restPersisted.title".tr(),
          subtitle: "networkExamples.restPersisted.subtitle".tr(),
          posts: state.restPersisted,
        ),
        const SizedBox(height: 16),
        _CountriesSection(
          title: "networkExamples.graphqlRemoteOnly.title".tr(),
          subtitle: "networkExamples.graphqlRemoteOnly.subtitle".tr(),
          countries: state.graphqlRemoteOnly,
        ),
        const SizedBox(height: 16),
        _CountriesSection(
          title: "networkExamples.graphqlPersisted.title".tr(),
          subtitle: "networkExamples.graphqlPersisted.subtitle".tr(),
          countries: state.graphqlPersisted,
        ),
      ],
    );
  }
}

final class _RestPostsSection extends StatelessWidget {
  const _RestPostsSection({
    required this.title,
    required this.subtitle,
    required this.posts,
  });

  final String title;
  final String subtitle;
  final List<RestPost> posts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(subtitle, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        if (posts.isEmpty)
          Text("networkExamples.empty".tr())
        else
          ...posts.map(
            (post) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(post.title, maxLines: 2),
              subtitle: Text(
                "networkExamples.restPostSubtitle".tr(
                  args: ["${post.userId}", "${post.id}"],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

final class _CountriesSection extends StatelessWidget {
  const _CountriesSection({
    required this.title,
    required this.subtitle,
    required this.countries,
  });

  final String title;
  final String subtitle;
  final List<GraphqlCountry> countries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(subtitle, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        if (countries.isEmpty)
          Text("networkExamples.empty".tr())
        else
          ...countries.map(
            (country) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(country.emoji),
              title: Text(country.name),
              subtitle: Text(
                "networkExamples.countrySubtitle".tr(
                  args: [country.code, country.capital ?? "-"],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
