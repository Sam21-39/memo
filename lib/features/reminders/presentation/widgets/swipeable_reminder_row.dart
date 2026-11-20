import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../l10n/l10n.dart';

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
  });

  static const actionWidth = 52.0;
  static const completeThreshold = 96.0;

  final Widget child;
  final VoidCallback? onComplete;
  final VoidCallback? onSnooze;
  final VoidCallback? onDelete;

  /// The row slides over the action buttons, so it must be opaque. Pass the
  /// surface it sits on — an overdue card is tinted, not plain surface.
  final Color? background;

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
      -SwipeableReminderRow.actionWidth *
      ((widget.onSnooze != null ? 1 : 0) + (widget.onDelete != null ? 1 : 0));

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: MemoMotion.base);
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
    ).animate(CurvedAnimation(parent: _controller, curve: MemoMotion.curve));
    void listener() => setState(() => _offset = animation.value);
    animation.addListener(listener);
    _controller.forward(from: 0).whenCompleteOrCancel(() {
      animation.removeListener(listener);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    final hasActions = widget.onSnooze != null || widget.onDelete != null;

    // VoiceOver / TalkBack cannot swipe a row; expose the same actions.
    return Semantics(
      customSemanticsActions: {
        if (widget.onComplete != null)
          CustomSemanticsAction(label: context.l10n.commonMarkDone):
              widget.onComplete!,
        if (widget.onSnooze != null)
          CustomSemanticsAction(label: context.l10n.commonSnoozeTenMinutes):
              widget.onSnooze!,
        if (widget.onDelete != null)
          CustomSemanticsAction(label: context.l10n.commonDelete):
              widget.onDelete!,
      },
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            _offset = (_offset + details.delta.dx).clamp(
              _openOffset,
              SwipeableReminderRow.completeThreshold + 40,
            );
          });
        },
        onHorizontalDragEnd: (_) {
          if (_offset > SwipeableReminderRow.completeThreshold) {
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
                        color: c.accent,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Icon(
                              Icons.check,
                              size: 19,
                              color: c.onAccent,
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
                        color: c.ink6,
                        label: context.l10n.snoozeTenMinutes,
                        labelColor: c.ink,
                        onTap: widget.onSnooze,
                      ),
                    if (widget.onDelete != null)
                      _ActionButton(
                        color: c.destructive,
                        label: context.l10n.commonDeleteShort,
                        labelColor: c.onAccent,
                        onTap: widget.onDelete,
                      ),
                  ],
                ),
              ),
            Transform.translate(
              offset: Offset(_offset, 0),
              child: ColoredBox(
                // Always opaque: the row slides over its action buttons, and a
                // translucent tint (accent-soft is 16 % in dark mode) would
                // show "10m" and "Del" through the text.
                color: Color.alphaBlend(
                  widget.background ?? c.surface,
                  c.surface,
                ),
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.color,
    required this.label,
    required this.labelColor,
    this.onTap,
  });

  final Color color;
  final String label;
  final Color labelColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: SwipeableReminderRow.actionWidth,
      child: Material(
        color: color,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: MemoType.labelMedium.copyWith(
                color: labelColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
