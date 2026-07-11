import "dart:async";

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:mvvm_starter/features/auth/domain/user.dart";
import "package:mvvm_starter/features/debug_database/presentation/database_debug_view_model.dart";

/// Debug database screen.
final class DatabaseDebugView extends StatefulWidget {
  /// Creates a debug database screen.
  const DatabaseDebugView({required this.viewModel, super.key});

  /// ViewModel for this screen.
  final DatabaseDebugViewModel viewModel;

  @override
  State<DatabaseDebugView> createState() => _DatabaseDebugViewState();
}

final class _DatabaseDebugViewState extends State<DatabaseDebugView> {
  DatabaseDebugViewModel get viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    unawaited(viewModel.init());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text("debug.database.title".tr()), elevation: 2),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ValueListenableBuilder<List<int>>(
              valueListenable: viewModel.sessions,
              builder: (context, sessions, child) {
                return _buildSessionsSection(theme, sessions);
              },
            ),
            const SizedBox(height: 32),
            ValueListenableBuilder<List<User>>(
              valueListenable: viewModel.users,
              builder: (context, users, child) {
                return _buildUsersSection(theme, users);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsSection(ThemeData theme, List<int> sessions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "debug.database.sessions".tr(),
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        if (sessions.isEmpty)
          _buildEmptyView(
            theme,
            icon: Icons.schedule_outlined,
            message: "debug.database.noSessions".tr(),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return Card(
                child: ListTile(
                  title: Text(
                    "debug.database.sessionUserId".tr(args: ["$session"]),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildUsersSection(ThemeData theme, List<User> users) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("debug.database.users".tr(), style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (users.isEmpty)
          _buildEmptyView(
            theme,
            icon: Icons.people_outline,
            message: "debug.database.noUsers".tr(),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    user.name[0].toUpperCase(),
                    style: TextStyle(color: theme.colorScheme.onPrimary),
                  ),
                ),
                title: Text(user.name, style: theme.textTheme.titleMedium),
                subtitle: Text(
                  "debug.database.userSubtitle".tr(
                    args: ["${user.id}", user.uid],
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                trailing: IconButton(
                  tooltip: "debug.database.deleteUser".tr(),
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await viewModel.deleteUser(user);
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyView(
    ThemeData theme, {
    required IconData icon,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: theme.colorScheme.secondary),
          const SizedBox(height: 16),
          Text(message, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }
}
