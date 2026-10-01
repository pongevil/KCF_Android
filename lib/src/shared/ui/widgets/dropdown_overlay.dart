import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Styled panel chrome for overlay dropdown lists (no layout push).
class DropdownOverlayPanel extends StatelessWidget {
  const DropdownOverlayPanel({
    super.key,
    required this.width,
    required this.borderColor,
    required this.backgroundColor,
    required this.borderRadius,
    required this.child,
    this.maxHeight = 220,
  });

  final double width;
  final Color borderColor;
  final Color backgroundColor;
  final double borderRadius;
  final double maxHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      shadowColor: Theme.of(context).shadowColor.withValues(alpha: 0.18),
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: width,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width, maxHeight: maxHeight),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(borderRadius),
                bottomRight: Radius.circular(borderRadius),
              ),
              border: Border(
                left: BorderSide(color: borderColor, width: 2),
                right: BorderSide(color: borderColor, width: 2),
                bottom: BorderSide(color: borderColor, width: 2),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(borderRadius),
                bottomRight: Radius.circular(borderRadius),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Hosts a field and shows an overlay list below it without pushing layout.
class DropdownOverlayPortal extends StatelessWidget {
  const DropdownOverlayPortal({
    super.key,
    required this.controller,
    required this.layerLink,
    required this.anchorKey,
    required this.tapRegionGroupId,
    required this.onTapOutside,
    required this.panelChild,
    required this.child,
    this.borderRadius = 13,
    this.maxHeight = 220,
  });

  final OverlayPortalController controller;
  final LayerLink layerLink;

  /// Key on the anchored field used to measure width.
  final GlobalKey anchorKey;
  final Object tapRegionGroupId;
  final VoidCallback onTapOutside;

  /// List content inside the overlay panel.
  final Widget panelChild;
  final Widget child;
  final double borderRadius;
  final double maxHeight;

  /// Match field width, but never spill past the right screen edge.
  double _panelWidth(BuildContext context) {
    final box = anchorKey.currentContext?.findRenderObject() as RenderBox?;
    final screenW = MediaQuery.sizeOf(context).width;
    if (box == null || !box.hasSize) {
      return screenW * 0.9;
    }

    final fieldW = box.size.width;
    final fieldLeft = box.localToGlobal(Offset.zero).dx;
    final maxW = math.max(0.0, screenW - fieldLeft - 1);
    return math.min(fieldW, maxW);
  }

  /// Cap panel height so it stays compact (~5–6 rows), not full-screen.
  double _resolvedMaxHeight(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final available = size.height - viewInsets.bottom;
    return math.min(maxHeight, available * 0.35);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return OverlayPortal(
      controller: controller,
      overlayChildBuilder: (context) {
        // OverlayPortal passes tight full-screen constraints. Align with
        // width/height factors shrink-wraps and loosens those constraints so
        // the panel keeps the field width (right border stays on-screen).
        return CompositedTransformFollower(
          link: layerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          child: Align(
            alignment: Alignment.topLeft,
            widthFactor: 1,
            heightFactor: 1,
            child: TapRegion(
              groupId: tapRegionGroupId,
              onTapOutside: (_) => onTapOutside(),
              child: DropdownOverlayPanel(
                width: _panelWidth(context),
                borderColor: cs.primaryContainer,
                backgroundColor: cs.surface,
                borderRadius: borderRadius,
                maxHeight: _resolvedMaxHeight(context),
                child: panelChild,
              ),
            ),
          ),
        );
      },
      child: TapRegion(
        groupId: tapRegionGroupId,
        child: CompositedTransformTarget(
          link: layerLink,
          child: KeyedSubtree(key: anchorKey, child: child),
        ),
      ),
    );
  }
}
