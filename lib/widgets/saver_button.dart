import 'package:flutter/material.dart';
import 'package:snap_saver/theme/theme.dart';

class SaverButton extends StatefulWidget {
  final String name;
  final int count;
  final bool showBadge;
  final Color? saverColor;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;

  const SaverButton({
    super.key,
    required this.name,
    this.count = 0,
    this.showBadge = false,
    this.saverColor,
    this.onPressed,
    this.onLongPress,
  });

  @override
  State<SaverButton> createState() => _SaverButtonState();
}

class _SaverButtonState extends State<SaverButton> {
  bool _isPressed = false;

  ColorScheme _buildColorScheme() {
    if (widget.saverColor != null) {
      return ColorScheme.fromSeed(
        seedColor: widget.saverColor!,
        brightness: Brightness.dark,
      );
    }
    return Theme.of(context).colorScheme;
  }

  @override
  Widget build(BuildContext context) {
    final saverColorScheme = _buildColorScheme();
    final bgColor = saverColorScheme.primary.withValues(alpha: 0.15);
    final fgColor = saverColorScheme.primary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onLongPress: widget.onLongPress,
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: fgColor.withValues(alpha: 0.3)),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InkWell(
              onTap: widget.onPressed,
              onLongPress: widget.onLongPress,
              borderRadius: BorderRadius.circular(AppRadius.md),
              splashColor: fgColor.withValues(alpha: 0.2),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        widget.name,
                        style: AppTypography.subheading(
                          size: 14,
                          weight: FontWeight.w600,
                        ).copyWith(color: fgColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.showBadge && widget.count > 0) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          widget.count.toString(),
                          style: AppTypography.caption(
                            size: 10,
                            weight: FontWeight.w700,
                          ).copyWith(color: AppColors.background),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
