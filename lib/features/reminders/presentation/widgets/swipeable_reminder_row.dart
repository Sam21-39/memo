import 'package:flutter/material.dart';

/// Swipe right → complete. Swipe left → reveal snooze (optional) + delete.
/// memo Design System · "Swipe actions". Pass [onSnooze] null when the
/// snooze feature flag is off — the row then reveals delete alone.
class SwipeableReminderRow extends StatefulWidget {
  const SwipeableReminderRow({
    super.key,
    required this.child,
    this.onComplete,
    this.onSnooze,
    this.onDelete,
    this.background,
    this.actionWidth = 52,
    this.completeThreshold = 96,
  });

  final Widget child;
  final VoidCallback? onComplete;
  final VoidCallback? onSnooze;
  final VoidCallback? onDelete;

  /// The row slides over the action buttons, so it must be opaque. Pass the
  /// surface it sits on — an overdue card is tinted, not plain surface.
  final Color? background;

  final double actionWidth;
  final double completeThreshold;

  @override
  State<SwipeableReminderRow> createState() => _SwipeableReminderRowState();
}

class _SwipeableReminderRowState extends State<SwipeableReminderRow>
    with SingleTickerProviderStateMixin {
  // Built eagerly in initState, not lazily: a row the user never swipes would
  // otherwise first touch the field inside dispose(), constructing a ticker
  // against an already-deactivated element.
  late final AnimationController _controller;
  double _offset = 0;

  double get _openOffset =>
      -widget.actionWidth *
      ((widget.onSnooze != null ? 1 : 0) + (widget.onDelete != null ? 1 : 0));

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    final animation = Tween(
      begin: _offset,
      end: target,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    void listener() => setState(() => _offset = animation.value);
    animation.addListener(listener);
    _controller.forward(from: 0).whenCompleteOrCancel(() {
      animation.removeListener(listener);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasActions = widget.onSnooze != null || widget.onDelete != null;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _offset = (_offset + details.delta.dx).clamp(
            _openOffset,
            widget.completeThreshold + 40,
          );
        });
      },
      onHorizontalDragEnd: (_) {
        if (_offset > widget.completeThreshold) {
          widget.onComplete?.call();
          _animateTo(0);
        } else if (_offset < _openOffset / 2 && hasActions) {
          _animateTo(_openOffset);
        } else {
          _animateTo(0);
        }
      },
      child: Stack(
        children: [
          // Complete affordance, revealed by dragging right.
          if (_offset > 0)
            Positioned.fill(
              child: Row(
                children: [
                  SizedBox(
                    width: _offset,
                    child: ColoredBox(
                      color: scheme.primary.withValues(
                        alpha: (_offset / widget.completeThreshold).clamp(
                          0.0,
                          1.0,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Icon(
                            Icons.check,
                            size: 19,
                            color: scheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          if (hasActions)
            Positioned.fill(
              child: Row(
                children: [
                  const Spacer(),
                  if (widget.onSnooze != null)
                    _ActionButton(
                      width: widget.actionWidth,
                      color: scheme.surfaceContainerHighest,
                      icon: Icons.snooze_outlined,
                      iconColor: scheme.onSurface.withValues(alpha: 0.6),
                      onTap: widget.onSnooze,
                    ),
                  if (widget.onDelete != null)
                    _ActionButton(
                      width: widget.actionWidth,
                      color: const Color(0xFFA33A2A),
                      icon: Icons.close,
                      iconColor: Colors.white,
                      onTap: widget.onDelete,
                    ),
                ],
              ),
            ),
          Transform.translate(
            offset: Offset(_offset, 0),
            child: ColoredBox(
              color: widget.background ?? scheme.surface,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.width,
    required this.color,
    required this.icon,
    required this.iconColor,
    this.onTap,
  });

  final double width;
  final Color color;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: color,
        child: InkWell(
          onTap: onTap,
          child: Icon(icon, color: iconColor, size: 19),
        ),
      ),
    );
  }
}
