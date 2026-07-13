import "dart:async";

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:mvvm_starter/app/routes.dart";
import "package:mvvm_starter/core/result/ui_state.dart";
import "package:mvvm_starter/features/network_examples/domain/network_example_models.dart";
import "package:mvvm_starter/features/network_examples/domain/persisted_result.dart";
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
            tooltip: "networkExamples.oidc.open".tr(),
            onPressed: () {
              context.pushNamed(AppRoute.oidcExample.name);
            },
            icon: const Icon(Icons.verified_user_outlined),
          ),
          ValueListenableBuilder<NetworkExamplesState>(
            valueListenable: viewModel.state,
            builder: (context, state, child) {
              return IconButton(
                key: const ValueKey("networkExamples.refreshButton"),
                tooltip: "networkExamples.refresh".tr(),
                onPressed: state.isLoading
                    ? null
                    : () {
                        unawaited(viewModel.load());
                      },
                icon: const Icon(Icons.refresh),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<NetworkExamplesState>(
        valueListenable: viewModel.state,
        builder: (context, state, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _RestPostsSection(
                title: "networkExamples.restRemoteOnly.title".tr(),
                subtitle: "networkExamples.restRemoteOnly.subtitle".tr(),
                state: state.restRemoteOnly,
              ),
              const SizedBox(height: 16),
              _PersistedRestPostsSection(
                title: "networkExamples.restPersisted.title".tr(),
                subtitle: "networkExamples.restPersisted.subtitle".tr(),
                state: state.restPersisted,
              ),
              const SizedBox(height: 16),
              _CountriesSection(
                title: "networkExamples.graphqlRemoteOnly.title".tr(),
                subtitle: "networkExamples.graphqlRemoteOnly.subtitle".tr(),
                state: state.graphqlRemoteOnly,
              ),
              const SizedBox(height: 16),
              _PersistedCountriesSection(
                title: "networkExamples.graphqlPersisted.title".tr(),
                subtitle: "networkExamples.graphqlPersisted.subtitle".tr(),
                state: state.graphqlPersisted,
              ),
            ],
          );
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

final class _RestPostsSection extends StatelessWidget {
  const _RestPostsSection({
    required this.title,
    required this.subtitle,
    required this.state,
  });

  final String title;
  final String subtitle;
  final UiState<List<RestPost>> state;

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      title: title,
      subtitle: subtitle,
      child: switch (state) {
        UiIdle<List<RestPost>>() => const SizedBox.shrink(),
        UiLoading<List<RestPost>>() => const LinearProgressIndicator(),
        UiFailure<List<RestPost>>(:final error) => Text(error.messageKey.tr()),
        UiSuccess<List<RestPost>>(:final value) => _RestPostsList(posts: value),
      },
    );
  }
}

final class _PersistedRestPostsSection extends StatelessWidget {
  const _PersistedRestPostsSection({
    required this.title,
    required this.subtitle,
    required this.state,
  });

  final String title;
  final String subtitle;
  final UiState<PersistedResult<List<RestPost>>> state;

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      title: title,
      subtitle: subtitle,
      child: switch (state) {
        UiIdle<PersistedResult<List<RestPost>>>() => const SizedBox.shrink(),
        UiLoading<PersistedResult<List<RestPost>>>() =>
          const LinearProgressIndicator(),
        UiFailure<PersistedResult<List<RestPost>>>(:final error) => Text(
          error.messageKey.tr(),
        ),
        UiSuccess<PersistedResult<List<RestPost>>>(:final value) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_originKey(value.origin).tr()),
            const SizedBox(height: 8),
            _RestPostsList(posts: value.value),
          ],
        ),
      },
    );
  }
}

final class _RestPostsList extends StatelessWidget {
  const _RestPostsList({required this.posts});

  final List<RestPost> posts;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return Text("networkExamples.empty".tr());
    }
    return Column(
      children: posts
          .map(
            (post) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(post.title, maxLines: 2),
              subtitle: Text(
                "networkExamples.restPostSubtitle".tr(
                  args: ["${post.userId}", "${post.id}"],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

final class _CountriesSection extends StatelessWidget {
  const _CountriesSection({
    required this.title,
    required this.subtitle,
    required this.state,
  });

  final String title;
  final String subtitle;
  final UiState<List<GraphqlCountry>> state;

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      title: title,
      subtitle: subtitle,
      child: switch (state) {
        UiIdle<List<GraphqlCountry>>() => const SizedBox.shrink(),
        UiLoading<List<GraphqlCountry>>() => const LinearProgressIndicator(),
        UiFailure<List<GraphqlCountry>>(:final error) => Text(
          error.messageKey.tr(),
        ),
        UiSuccess<List<GraphqlCountry>>(:final value) => _CountriesList(
          countries: value,
        ),
      },
    );
  }
}

final class _PersistedCountriesSection extends StatelessWidget {
  const _PersistedCountriesSection({
    required this.title,
    required this.subtitle,
    required this.state,
  });

  final String title;
  final String subtitle;
  final UiState<PersistedResult<List<GraphqlCountry>>> state;

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      title: title,
      subtitle: subtitle,
      child: switch (state) {
        UiIdle<PersistedResult<List<GraphqlCountry>>>() =>
          const SizedBox.shrink(),
        UiLoading<PersistedResult<List<GraphqlCountry>>>() =>
          const LinearProgressIndicator(),
        UiFailure<PersistedResult<List<GraphqlCountry>>>(:final error) => Text(
          error.messageKey.tr(),
        ),
        UiSuccess<PersistedResult<List<GraphqlCountry>>>(:final value) =>
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_originKey(value.origin).tr()),
              const SizedBox(height: 8),
              _CountriesList(countries: value.value),
            ],
          ),
      },
    );
  }
}

final class _CountriesList extends StatelessWidget {
  const _CountriesList({required this.countries});

  final List<GraphqlCountry> countries;

  @override
  Widget build(BuildContext context) {
    if (countries.isEmpty) {
      return Text("networkExamples.empty".tr());
    }
    return Column(
      children: countries
          .map(
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
          )
          .toList(),
    );
  }
}

final class _SectionFrame extends StatelessWidget {
  const _SectionFrame({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

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
        child,
      ],
    );
  }
}

String _originKey(DataOrigin origin) => switch (origin) {
  DataOrigin.remote => "networkExamples.origin.remote",
  DataOrigin.localFresh => "networkExamples.origin.localFresh",
  DataOrigin.localStale => "networkExamples.origin.localStale",
};
