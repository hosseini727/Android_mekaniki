import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppBottomNavItem {
  const AppBottomNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.items,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<AppBottomNavItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.navBarTop, AppColors.navBarBottom],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(
          top: BorderSide(color: AppColors.primary.withValues(alpha: 0.22)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                _NavTile(
                  item: items[i],
                  selected: i == selectedIndex,
                  onTap: () => onSelected(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppBottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: AppColors.primary.withValues(alpha: 0.12),
          highlightColor: AppColors.primary.withValues(alpha: 0.06),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  width: selected ? 52 : 44,
                  height: selected ? 36 : 32,
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [AppColors.primary, AppColors.primaryDark],
                          )
                        : LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.95),
                              AppColors.line.withValues(alpha: 0.35),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.35)
                          : AppColors.line.withValues(alpha: 0.7),
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.38),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Icon(
                    selected ? item.selectedIcon : item.icon,
                    size: selected ? 22 : 21,
                    color: selected ? AppColors.onPrimary : AppColors.muted,
                  ),
                ),
                const SizedBox(height: 5),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: selected ? 12 : 11,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? AppColors.primaryDark : AppColors.muted,
                    height: 1.1,
                  ),
                  child: Text(item.label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
