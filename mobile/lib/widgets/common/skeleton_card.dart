import 'package:flutter/material.dart';

/// Reusable self-contained Shimmer Skeleton loader for ultra-smooth,
/// premium loading states without blank screens.
class SkeletonCard extends StatefulWidget {
  final double height;
  final double? width;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const SkeletonCard({
    super.key,
    this.height = 100,
    this.width,
    this.borderRadius = 16,
    this.margin,
    this.padding,
  });

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          margin: widget.margin,
          padding: widget.padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0D1620).withValues(alpha: _animation.value),
                const Color(0xFF1D3347).withValues(alpha: _animation.value * 0.9),
                const Color(0xFF0D1620).withValues(alpha: _animation.value),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        );
      },
    );
  }
}

/// A structured Skeleton List Item loader matching task & transaction cards
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1620),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1D3347)),
      ),
      child: const Row(
        children: [
          SkeletonCard(width: 44, height: 44, borderRadius: 12),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonCard(height: 16, width: 140, borderRadius: 6),
                SizedBox(height: 8),
                SkeletonCard(height: 12, width: 90, borderRadius: 4),
              ],
            ),
          ),
          SizedBox(width: 12),
          SkeletonCard(height: 24, width: 70, borderRadius: 8),
        ],
      ),
    );
  }
}

/// Skeleton loader for metric dashboards
class SkeletonMetricsRow extends StatelessWidget {
  const SkeletonMetricsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: SkeletonCard(height: 85, borderRadius: 14)),
        SizedBox(width: 12),
        Expanded(child: SkeletonCard(height: 85, borderRadius: 14)),
        SizedBox(width: 12),
        Expanded(child: SkeletonCard(height: 85, borderRadius: 14)),
      ],
    );
  }
}
