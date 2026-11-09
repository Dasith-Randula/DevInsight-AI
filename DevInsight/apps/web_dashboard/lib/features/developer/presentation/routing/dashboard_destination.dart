import 'package:flutter/material.dart';

enum DashboardDestination {
  home(label: 'Home', route: '/dashboard/home', icon: Icons.home_rounded),
  projects(
    label: 'Projects',
    route: '/dashboard/projects',
    icon: Icons.folder_open_rounded,
  ),
  myWork(
    label: 'My Work',
    route: '/dashboard/my-work',
    icon: Icons.bar_chart_rounded,
  ),
  issues(
    label: 'Issues',
    route: '/dashboard/issues',
    icon: Icons.bug_report_outlined,
  ),
  pullRequests(
    label: 'Pull Requests',
    route: '/dashboard/pull-requests',
    icon: Icons.merge_rounded,
  ),
  codeQuality(
    label: 'Code Quality',
    route: '/dashboard/code-quality',
    icon: Icons.verified_outlined,
  ),
  analytics(
    label: 'Analytics',
    route: '/dashboard/analytics',
    icon: Icons.show_chart_rounded,
  ),
  aiInsights(
    label: 'AI Insights',
    route: '/dashboard/ai-insights',
    icon: Icons.auto_awesome_rounded,
  ),
  team(
    label: 'Team',
    route: '/dashboard/team',
    icon: Icons.people_outline_rounded,
  ),
  reports(
    label: 'Reports',
    route: '/dashboard/reports',
    icon: Icons.description_outlined,
  ),
  settings(
    label: 'Settings',
    route: '/dashboard/settings',
    icon: Icons.settings_outlined,
  );

  const DashboardDestination({
    required this.label,
    required this.route,
    required this.icon,
  });

  final String label;
  final String route;
  final IconData icon;

  bool get isWorkspace => index >= DashboardDestination.team.index;

  static DashboardDestination fromRoute(String route) =>
      DashboardDestination.values.firstWhere(
        (destination) => destination.route == route,
        orElse: () => throw ArgumentError.value(route, 'route'),
      );
}
