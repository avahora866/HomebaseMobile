import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum DrawerDestination { home, budget, netWorth, settings }

/// The two destinations that sit under the Finance parent — the group starts
/// expanded whenever one of them is the active screen.
const _financeDestinations = {DrawerDestination.budget, DrawerDestination.netWorth};

/// The hamburger-triggered drawer: a backdrop plus a 76%-wide panel sliding
/// in from the left, matching the prototype's `.drawer-backdrop` /
/// `.drawer` — an absolutely-positioned overlay rather than Flutter's
/// built-in end-drawer mechanics, so it can sit inside the same screen and
/// animate open/closed exactly like the design.
class AppDrawerOverlay extends StatefulWidget {
  final bool open;
  final DrawerDestination active;
  final VoidCallback onClose;
  final VoidCallback onHome;
  final VoidCallback onBudget;
  final VoidCallback onNetWorth;
  final VoidCallback onSettings;

  const AppDrawerOverlay({
    super.key,
    required this.open,
    required this.active,
    required this.onClose,
    required this.onHome,
    required this.onBudget,
    required this.onNetWorth,
    required this.onSettings,
  });

  @override
  State<AppDrawerOverlay> createState() => _AppDrawerOverlayState();
}

class _AppDrawerOverlayState extends State<AppDrawerOverlay> {
  late bool _financeExpanded = _financeDestinations.contains(widget.active);

  @override
  void didUpdateWidget(AppDrawerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active && _financeDestinations.contains(widget.active)) {
      _financeExpanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.open,
      child: Stack(
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: widget.open ? 1 : 0,
            child: GestureDetector(
              onTap: widget.onClose,
              child: Container(color: Colors.black.withValues(alpha: 0.45)),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            top: 0,
            bottom: 0,
            left: widget.open ? 0 : -MediaQuery.of(context).size.width * 0.76,
            width: MediaQuery.of(context).size.width * 0.76,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.bg,
                border: Border(right: BorderSide(color: AppColors.divider, width: 2)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
                        child: Text('Homebase', style: AppTypography.heading(19)),
                      ),
                      _DrawerItem(
                        label: 'Home',
                        active: widget.active == DrawerDestination.home,
                        onTap: widget.onHome,
                      ),
                      _DrawerParent(
                        label: 'Finance',
                        expanded: _financeExpanded,
                        active: _financeDestinations.contains(widget.active),
                        onTap: () => setState(() => _financeExpanded = !_financeExpanded),
                      ),
                      if (_financeExpanded) ...[
                        _DrawerItem(
                          label: 'Budget',
                          active: widget.active == DrawerDestination.budget,
                          onTap: widget.onBudget,
                          nested: true,
                        ),
                        _DrawerItem(
                          label: 'Net Worth',
                          active: widget.active == DrawerDestination.netWorth,
                          onTap: widget.onNetWorth,
                          nested: true,
                        ),
                      ],
                      _DrawerItem(
                        label: 'Settings',
                        active: widget.active == DrawerDestination.settings,
                        onTap: widget.onSettings,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A group header — tapping it expands/collapses the group rather than
/// navigating, so "Finance" itself is never a destination.
class _DrawerParent extends StatelessWidget {
  final String label;
  final bool expanded;
  final bool active;
  final VoidCallback onTap;
  const _DrawerParent({
    required this.label,
    required this.expanded,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 22),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: active ? AppColors.accent : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.heading(
                  14,
                  weight: FontWeight.w600,
                  color: active ? AppColors.accent : AppColors.text,
                ),
              ),
            ),
            Icon(
              expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: active ? AppColors.accent : AppColors.ink(0.55),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  /// Sub-items sit under a [_DrawerParent] — indented and a step smaller than
  /// a top-level entry.
  final bool nested;

  const _DrawerItem({
    required this.label,
    required this.active,
    required this.onTap,
    this.nested = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(nested ? 38 : 22, nested ? 11 : 13, 22, nested ? 11 : 13),
        decoration: BoxDecoration(
          color: active ? AppColors.surface : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: active ? AppColors.accent : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.heading(
            nested ? 13 : 14,
            weight: FontWeight.w600,
            color: active ? AppColors.accent : AppColors.text,
          ),
        ),
      ),
    );
  }
}
