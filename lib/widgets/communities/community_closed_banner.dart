import 'dart:async';

import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:citizenwallet/l10n/app_localizations.dart';

// The CommunityClosedBanner class remains the same.
class CommunityClosedBanner extends StatefulWidget {
  final VoidCallback? handleOffboardPlugin;
  final VoidCallback? onDismiss;
  final bool display;
  final PluginConfig? offboardPlugin;

  const CommunityClosedBanner({
    super.key,
    this.handleOffboardPlugin,
    this.onDismiss,
    this.display = false,
    this.offboardPlugin,
  });

  @override
  State<CommunityClosedBanner> createState() => _CommunityClosedBannerState();
}

// ====================================================================
// Refactored State Class
// ====================================================================

class _CommunityClosedBannerState extends State<CommunityClosedBanner>
    with SingleTickerProviderStateMixin {
  // ADD this Mixin

  // Existing state variables
  bool _display = false;
  double _slideOffset = 100;
  bool _isDismissed = false;

  // Keep these for tracking the current drag and its position
  double _dragOffset = 0;
  bool _isDragging = false;

  // New: Animation Controller for the drag effect (snap-back or final dismissal)
  late AnimationController _dragAnimationController;
  late Animation<double> _dragAnimation;

  Timer? _showTimer;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();

    _display = widget.display;
    _slideOffset = widget.display ? 0 : 100;

    _dragAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(_handleAnimationUpdate);

    // 💡 FIX: Initialize _dragAnimation here with a default value of 0
    _dragAnimation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(_dragAnimationController);
  }

  // New: Listener for the drag animation
  void _handleAnimationUpdate() {
    setState(() {
      // The current drag offset is controlled by the animation when not dragging
      _dragOffset = _dragAnimation.value;
    });
    // If the animation is completing and it was a dismissal animation, call hide
    if (_dragAnimationController.isCompleted && !_isDragging && _isDismissed) {
      // This hide call completes the process by setting _display = false
      // and animating the main widget's slide offset back to 100
      hide();
    }
  }

  @override
  void didUpdateWidget(CommunityClosedBanner oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_isDismissed) return;

    if (widget.display != oldWidget.display) {
      if (widget.display) {
        show();
      } else {
        hide();
      }
    }
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _dragAnimationController.dispose(); // DISPOSE the controller
    super.dispose();
  }

  void show() async {
    if (_isDismissed) return;

    setState(() {
      _display = true;
      _dragOffset = 0; // Ensure reset on show
      _isDragging = false; // Ensure reset on show
    });

    _hideTimer?.cancel();
    _showTimer = Timer(const Duration(milliseconds: 50), () {
      HapticFeedback.heavyImpact();

      setState(() {
        _slideOffset = 0;
      });
    });
  }

  void hide() async {
    setState(() {
      _slideOffset = 100;
    });

    _showTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 400), () {
      HapticFeedback.lightImpact();

      setState(() {
        _display = false;
      });
    });
  }

  void handleLearnMore() {
    widget.handleOffboardPlugin?.call();
  }

  void handleDismiss() {
    // Only set _isDismissed and call onDismiss. The visual dismissal animation
    // is now handled by _handleDragEnd/AnimatedBuilder.
    setState(() {
      _isDismissed = true;
    });
    widget.onDismiss?.call();
    // hide() is called after the dismissal animation completes in _handleAnimationUpdate
  }

  void _handleDragStart(DragStartDetails details) {
    // Stop any ongoing animation before starting a new drag
    _dragAnimationController.stop();
    setState(() {
      _isDragging = true;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      // 1. Update the drag offset based on user movement (details.delta.dy)
      // Dragging down (dy > 0) increases _dragOffset.
      // Dragging up (dy < 0) decreases _dragOffset.
      _dragOffset += details.delta.dy * 0.8;

      // 2. ⚠️ Recommended FIX: Clamp the drag offset to prevent it from becoming negative.
      // A negative _dragOffset translates the banner UP. By clamping at 0,
      // we ensure the banner cannot move up past its fully displayed state.
      if (_dragOffset < 0) {
        _dragOffset = 0;
      }

      // The previous 'if (_dragOffset < 0 && _slideOffset < 100)' block
      // is no longer necessary, as the clamp handles the restriction.
      // Any content related to upward drag logic (like the -50 limit)
      // is also overridden by the strict clamp at 0.
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final screenHeight = MediaQuery.of(context).size.height;
    // Lower the threshold to make dismissal easier
    final dismissThreshold = screenHeight * 0.15; // 15% of screen height

    // Calculate the target end position for the animation
    final double targetEndOffset;
    final bool shouldDismiss;

    if (_dragOffset > dismissThreshold || velocity > 400) {
      // ⬇️ DRAG DOWN TO DISMISS
      HapticFeedback.mediumImpact();
      shouldDismiss = true;
      targetEndOffset = screenHeight;
    } else if (_dragOffset < 0 && _dragOffset.abs() > 10) {
      // ⬆️ DRAG UP (Optional: check if drag up gesture was significant)
      // If you wanted a "compacted" state on drag up, this is where you'd set targetEndOffset to a small negative value.
      // For now, we'll just snap back to 0.
      HapticFeedback.lightImpact();
      shouldDismiss = false;
      targetEndOffset = 0; // Snap back to origin
    } else {
      // ➖ SNAP BACK (Not enough drag in either direction)
      HapticFeedback.lightImpact();
      shouldDismiss = false;
      targetEndOffset = 0;
    }

    // Set dragging to false
    setState(() {
      _isDragging = false;
    });

    if (shouldDismiss) {
      handleDismiss(); // Call handleDismiss to set _isDismissed = true
    }

    // Configure and start the animation for snap-back or dismissal
    _dragAnimation = Tween<double>(
      begin: _dragOffset,
      end: targetEndOffset,
    ).animate(CurvedAnimation(
      parent: _dragAnimationController,
      curve: shouldDismiss
          ? Curves.easeOut
          : Curves.easeOutCubic, // Different curves for dismissal vs snap-back
    ));

    // Reset controller and start the animation
    _dragAnimationController.reset();
    _dragAnimationController.forward();

    // Note: The final call to hide() happens in _handleAnimationUpdate
    // when the dismissal animation completes.
  }

  @override
  Widget build(BuildContext context) {
    if (!_display) {
      return const SizedBox();
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final safeBottomPadding = MediaQuery.of(context).padding.bottom;
    final bannerHeight = screenHeight - 300;

    // Use a temporary variable for the current drag offset:
    // It's either the real-time drag (if dragging) or the animated value (if snapping back/dismissing)
    final currentDragOffset = _isDragging ? _dragOffset : _dragAnimation.value;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onVerticalDragStart: _handleDragStart,
        onVerticalDragUpdate: _handleDragUpdate,
        onVerticalDragEnd: _handleDragEnd,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _slideOffset, 0),
          height: bannerHeight,
          child: AnimatedBuilder(
            animation: _dragAnimationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, currentDragOffset),
                child: child,
              );
            },
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 10, 20, safeBottomPadding + 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F0),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle indicator
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 8, bottom: 30),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.info_circle_fill,
                            size: 60,
                            color: Theme.of(context)
                                .colors
                                .primary
                                .resolveFrom(context),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              widget.offboardPlugin?.meta?['title']
                                      as String? ??
                                  AppLocalizations.of(context)!.communityClosed,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Text(
                              widget.offboardPlugin?.meta?['desc'] as String? ??
                                  AppLocalizations.of(context)!
                                      .communityClosedDescription,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: Theme.of(context)
                                    .colors
                                    .black
                                    .withOpacity(0.7),
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          if (widget.handleOffboardPlugin != null)
                            CupertinoButton(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 14,
                              ),
                              color: Theme.of(context)
                                  .colors
                                  .primary
                                  .resolveFrom(context),
                              borderRadius: BorderRadius.circular(25),
                              onPressed: handleLearnMore,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.offboardPlugin?.meta?['button']
                                            as String? ??
                                        AppLocalizations.of(context)!.learnMore,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    CupertinoIcons.arrow_right_circle_fill,
                                    color: Theme.of(context).colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
