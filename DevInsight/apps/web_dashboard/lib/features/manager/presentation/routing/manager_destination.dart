import 'package:flutter/material.dart';

enum ManagerDestination {
  home(label: 'Home', route: '/manager/home', icon: Icons.home_rounded),
  projects(
    label: 'Projects',
    route: '/manager/projects',
    icon: Icons.folder_open_rounded,
  ),
  issues(
    label: 'Issues & Priorities',
    route: '/manager/issues',
    icon: Icons.low_priority_rounded,
  ),
  team(
    label: 'Team & Workload',
    route: '/manager/team',
    icon: Icons.people_outline_rounded,
  ),
  analytics(
    label: 'Project Analytics',
    route: '/manager/analytics',
    icon: Icons.show_chart_rounded,
  ),
  reports(
    label: 'Reports',
    route: '/manager/reports',
    icon: Icons.description_outlined,
  ),
  settings(
    label: 'Settings',
    route: '/manager/settings',
    icon: Icons.settings_outlined,
  );

  const ManagerDestination({
    required this.label,
    required this.route,
    required this.icon,
  });

  final String label;
  final String route;
  final IconData icon;
}
