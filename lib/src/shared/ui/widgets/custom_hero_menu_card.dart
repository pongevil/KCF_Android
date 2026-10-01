import 'package:bs_mobile/src/shared/ui/widgets/app_text.dart';
import 'package:flutter/material.dart';

class CustomHeroMenuCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const CustomHeroMenuCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  State<CustomHeroMenuCard> createState() => _CustomHeroMenuCardState();
}

class _CustomHeroMenuCardState extends State<CustomHeroMenuCard>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _floatController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pressController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _pressController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _pressController.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final onGradient = Theme.of(context).colorScheme.onPrimary;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.gradientColors,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.gradientColors.last.withOpacity(
                    _isPressed ? 0.2 : 0.4,
                  ),
                  blurRadius: _isPressed ? 8 : 20,
                  offset: _isPressed ? const Offset(0, 4) : const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  // Decorative background circles
                  Positioned(
                    right: -40,
                    top: -40,
                    child: AnimatedBuilder(
                      animation: _floatController,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, _floatController.value * 15),
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: onGradient.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 60,
                    bottom: -40,
                    child: AnimatedBuilder(
                      animation: _floatController,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, -_floatController.value * 10),
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: onGradient.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Large Icon background
                  Positioned(
                    right: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _floatController,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(0, _floatController.value * 5 - 2.5),
                          child: Icon(
                            widget.icon,
                            size: 110,
                            color: onGradient.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: onGradient.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(widget.icon, color: onGradient, size: 28),
                        ),
                        const Spacer(),
                        AppText(
                          widget.title,
                          color: Theme.of(context).colorScheme.onSurface,
                          style: TextStyle(
                            color: onGradient,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            shadows: [
                              Shadow(
                                color: Theme.of(
                                  context,
                                ).shadowColor.withValues(alpha: 0.12),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        AppText(
                          widget.subtitle,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          style: TextStyle(
                            color: onGradient.withValues(alpha: 0.95),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Arrow indicator
                  Positioned(
                    right: 24,
                    bottom: 24,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: onGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).shadowColor.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: widget.gradientColors.last,
                        size: 14,
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
