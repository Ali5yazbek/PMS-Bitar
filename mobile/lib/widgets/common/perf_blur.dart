import 'dart:ui';
import 'package:flutter/widgets.dart';

/// Drop-in replacement for `BackdropFilter` on persistent chrome (app bar, bottom navigation,
/// bottom sheets).
///
/// A live backdrop blur over scrolling content forces the GPU to re-blur everything behind the
/// widget on EVERY frame, which is the single biggest cause of dropped frames on 2-3 GB devices.
/// The gradients used by those surfaces are already ~92% opaque, so the visual difference is
/// negligible, while the saving is large. The `filter` argument is accepted (and ignored) so
/// call-sites keep their original shape.
class PerfBlur extends StatelessWidget {
  const PerfBlur({super.key, required this.filter, required this.child});

  final ImageFilter filter;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

