import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum DrawerDestination { home, settings }

/// The hamburger-triggered drawer: a backdrop plus a 76%-wide panel sliding
/// in from the left, matching the prototype's `.drawer-backdrop` /
/// `.drawer` — an absolutely-positioned overlay rather than Flutter's
/// built-in end-drawer mechanics, so it can sit inside the same screen and
/// animate open/closed exactly like the design.
class AppDrawerOverlay extends StatelessWidget {
  final bool open;
  final DrawerDestination active;
  final VoidCallback onClose;
  final VoidCallback onHome;
  final VoidCallback onSettings;

  const AppDrawerOverlay({
    super.key,
    required this.open,
    required this.active,
    required this.onClose,
    required this.onHome,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !open,
      child: Stack(
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: open ? 1 : 0,
            child: GestureDetector(
              onTap: onClose,
              child: Container(color: Colors.black.withValues(alpha: 0.45)),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            top: 0,
            bottom: 0,
            left: open ? 0 : -MediaQuery.of(context).size.width * 0.76,
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
                        active: active == DrawerDestination.home,
                        onTap: onHome,
                      ),
                      _DrawerItem(
                        label: 'Settings',
                        active: active == DrawerDestination.settings,
                        onTap: onSettings,
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

class _DrawerItem extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _DrawerItem({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 22),
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
            14,
            weight: FontWeight.w600,
            color: active ? AppColors.accent : AppColors.text,
          ),
        ),
      ),
    );
  }
}
