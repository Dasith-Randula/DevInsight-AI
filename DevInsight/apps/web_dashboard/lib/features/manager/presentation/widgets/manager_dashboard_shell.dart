import 'package:flutter/material.dart';
import 'package:web_dashboard/core/theme/app_theme_extension.dart';
import 'package:web_dashboard/features/manager/presentation/routing/manager_destination.dart';
import 'package:web_dashboard/shared/widgets/dashboard_chrome.dart';

class ManagerDashboardShell extends StatelessWidget {
  const ManagerDashboardShell({
    super.key,
    required this.profileName,
    required this.role,
    required this.email,
    required this.activeDestination,
    required this.scrollController,
    required this.ambientMotion,
    required this.onDestinationSelected,
    required this.onProfile,
    required this.onAction,
    required this.onHelp,
    required this.child,
  });

  final String profileName;
  final String role;
  final String? email;
  final ManagerDestination activeDestination;
  final ScrollController scrollController;
  final Animation<double> ambientMotion;
  final ValueChanged<ManagerDestination> onDestinationSelected;
  final VoidCallback onProfile;
  final ValueChanged<String> onAction;
  final VoidCallback onHelp;
  final Widget child;

  DashboardNavigationItem<ManagerDestination> _item(
    ManagerDestination destination,
  ) => DashboardNavigationItem(
    value: destination,
    label: destination.label,
    icon: destination.icon,
    key: ValueKey('manager-nav-${destination.name}'),
  );

  void _selectFromDrawer(BuildContext context, ManagerDestination destination) {
    Navigator.of(context).pop();
    onDestinationSelected(destination);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    final items = ManagerDestination.values.map(_item).toList();
    return Scaffold(
      backgroundColor: colors.secondaryBackground,
      drawer: Drawer(
        width: 272,
        child: SafeArea(
          child: DashboardNavigation<ManagerDestination>(
            primaryItems: items,
            workspaceItems: const [],
            activeValue: activeDestination,
            onSelect: (destination) => _selectFromDrawer(context, destination),
            onHelp: () {
              Navigator.of(context).pop();
              onHelp();
            },
            expanded: true,
          ),
        ),
      ),
      body: DashboardBackground(
        animation: ambientMotion,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final desktop = constraints.maxWidth >= 900;
              return Stack(
                children: [
                  Positioned.fill(
                    left: desktop ? 76 : 0,
                    child: Stack(
                      key: const ValueKey('manager-dashboard-content'),
                      children: [
                        Positioned.fill(
                          child: SingleChildScrollView(
                            key: const ValueKey('manager-scroll-view'),
                            controller: scrollController,
                            padding: EdgeInsets.fromLTRB(
                              constraints.maxWidth < 600 ? 14 : 24,
                              78,
                              constraints.maxWidth < 600 ? 14 : 24,
                              28,
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 1500,
                                ),
                                child: DefaultTextStyle(
                                  style: TextStyle(color: colors.primaryText),
                                  child: KeyedSubtree(
                                    key: ValueKey(
                                      'manager-${activeDestination.name}',
                                    ),
                                    child: child,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: DashboardTopBar(
                            name: profileName,
                            role: role,
                            scrollController: scrollController,
                            onMenu: desktop
                                ? null
                                : () => Scaffold.of(context).openDrawer(),
                            onProfile: onProfile,
                            onAction: onAction,
                            onSettings: () => onDestinationSelected(
                              ManagerDestination.settings,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (desktop)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: DashboardNavigation<ManagerDestination>(
                        primaryItems: items,
                        workspaceItems: const [],
                        activeValue: activeDestination,
                        onSelect: onDestinationSelected,
                        onHelp: onHelp,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
