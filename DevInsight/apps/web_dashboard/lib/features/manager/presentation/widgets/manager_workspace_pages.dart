import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_dashboard/core/services/devinsight_api.dart';
import 'package:web_dashboard/core/theme/app_theme_extension.dart';
import 'package:web_dashboard/core/theme/theme_controller.dart';
import 'package:web_dashboard/features/developer/presentation/widgets/dashboard_page_widgets.dart';
import 'package:web_dashboard/features/manager/presentation/routing/manager_destination.dart';
import 'package:web_dashboard/shared/widgets/theme_toggle_button.dart';
import 'package:web_dashboard/shared/widgets/dashboard_scroll_indicator.dart';
import 'package:web_dashboard/shared/widgets/devinsight_animated_wordmark.dart';

part '../pages/manager_home_content.dart';
part '../pages/manager_projects_page.dart';
part '../pages/manager_issues_page.dart';
part '../pages/manager_team_page.dart';
part '../pages/manager_analytics_page.dart';
part '../pages/manager_reports_page.dart';
part '../pages/manager_settings_page.dart';
part 'manager_workspace_widgets.dart';

class ManagerWorkspaceData {
  const ManagerWorkspaceData({
    required this.profile,
    required this.scrollController,
    required this.currentProjectKey,
    required this.repositories,
    required this.repository,
    required this.overview,
    required this.loading,
    required this.refreshing,
    required this.error,
    required this.onSelectRepository,
    required this.onConnectRepository,
    required this.onRefresh,
    required this.onRetry,
    required this.onOpenLink,
    required this.onNavigate,
    required this.onMessage,
    required this.onSignOut,
  });

  final CurrentUserProfile profile;
  final ScrollController scrollController;
  final GlobalKey currentProjectKey;
  final List<GitHubRepositoryConnection> repositories;
  final GitHubRepositoryConnection? repository;
  final GitHubRepositoryOverview? overview;
  final bool loading;
  final bool refreshing;
  final String? error;
  final ValueChanged<GitHubRepositoryConnection> onSelectRepository;
  final VoidCallback onConnectRepository;
  final VoidCallback onRefresh;
  final VoidCallback onRetry;
  final ValueChanged<String> onOpenLink;
  final ValueChanged<ManagerDestination> onNavigate;
  final ValueChanged<String> onMessage;
  final VoidCallback onSignOut;
}
