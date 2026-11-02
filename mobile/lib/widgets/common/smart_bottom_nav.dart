import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_theme.dart';

class SmartNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;

  const SmartNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}

class SmartBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<SmartNavItem> items;
  final ValueChanged<int> onTap;
  final VoidCallback? onMoreTap;

  const SmartBottomNav({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        bottom: bottomPadding > 0 ? bottomPadding : 14,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xEB0C1620),
                  Color(0xF2070D14),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.22),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.65),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isMore = item.label == 'More';
                final isSelected = index == currentIndex && !isMore;

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (isMore && onMoreTap != null) {
                        onMoreTap!();
                      } else {
                        onTap(index);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppTheme.primary.withValues(alpha: 0.22),
                                  AppTheme.primary.withValues(alpha: 0.06),
                                ],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(22),
                        border: isSelected
                            ? Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.38),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedTransform(
                            duration: const Duration(milliseconds: 260),
                            transform: isSelected
                                ? (Matrix4.identity()..translate(0.0, -1.5, 0.0)..scale(1.12))
                                : Matrix4.identity(),
                            child: Icon(
                              isSelected ? item.activeIcon : item.icon,
                              size: 21,
                              color: isSelected
                                  ? AppTheme.primary
                                  : (isMore ? AppTheme.accent : AppTheme.textSecondary),
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 260),
                            style: GoogleFonts.outfit(
                              color: isSelected
                                  ? Colors.white
                                  : (isMore ? AppTheme.accent : AppTheme.textSecondary),
                              fontSize: isSelected ? 10.5 : 10,
                              fontWeight: isSelected || isMore ? FontWeight.w700 : FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 3),
                          // Active glowing gold/teal indicator dot
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            width: isSelected ? 14 : 0,
                            height: 2.5,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.primary.withValues(alpha: 0.7),
                                        blurRadius: 6,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedTransform extends StatelessWidget {
  final Duration duration;
  final Matrix4 transform;
  final Widget child;

  const AnimatedTransform({
    super.key,
    required this.duration,
    required this.transform,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      transform: transform,
      transformAlignment: Alignment.center,
      child: child,
    );
  }
}
