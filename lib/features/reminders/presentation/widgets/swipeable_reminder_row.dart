import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/ui/memo_sheet.dart';
import '../../../../core/ui/motion.dart';
import 'key_value_row.dart';
import 'section_card.dart';
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
    this.onEdit,
    this.title,
    this.background,
  });

  static const actionWidth = 72.0;
  static const completeThreshold = 96.0;

  final Widget child;
  final VoidCallback? onComplete;
  final VoidCallback? onSnooze;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  /// Heads the long-press menu.
  final String? title;

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
  bool _crossed = false;

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
    _controller.duration = motion(context, MemoMotion.base);
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
        if (widget.onEdit != null)
          CustomSemanticsAction(label: context.l10n.commonEdit): widget.onEdit!,
        if (widget.onDelete != null)
          CustomSemanticsAction(label: context.l10n.commonDelete):
              widget.onDelete!,
      },
      child: GestureDetector(
        onLongPress: widget.title == null
            ? null
            : () => showRowActions(
                context,
                title: widget.title!,
                onComplete: widget.onComplete,
                onSnooze: widget.onSnooze,
                onEdit: widget.onEdit,
                onDelete: widget.onDelete,
              ),
        onHorizontalDragUpdate: (details) {
          setState(() {
            _offset = (_offset + details.delta.dx).clamp(
              _openOffset,
              SwipeableReminderRow.completeThreshold + 40,
            );
          });
          final crossed = _offset > SwipeableReminderRow.completeThreshold;
          if (crossed != _crossed) {
            _crossed = crossed;
            if (crossed) HapticFeedback.selectionClick();
          }
        },
        onHorizontalDragEnd: (_) {
          _crossed = false;
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
                            // Revealed as it widens; never laid out narrower.
                            child: ClipRect(
                              child: OverflowBox(
                                alignment: Alignment.centerLeft,
                                maxWidth: double.infinity,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check,
                                      size: 19,
                                      color: c.onAccent,
                                    ),
                                    const SizedBox(width: MemoSpace.space2),
                                    Text(
                                      context.l10n.commonDone,
                                      softWrap: false,
                                      style: MemoType.labelMedium.copyWith(
                                        color: c.onAccent,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                        label: context.l10n.swipeSnooze,
                        labelColor: c.ink,
                        onTap: widget.onSnooze,
                      ),
                    if (widget.onDelete != null)
                      _ActionButton(
                        color: c.destructive,
                        label: context.l10n.commonDelete,
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
            // Full words; shrinks rather than breaking one at large text.
            child: Padding(
              padding: const EdgeInsets.all(MemoSpace.space1),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: MemoType.labelMedium.copyWith(
                    color: labelColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The same four actions as the swipe, for a long press. Each closes the
/// sheet, then runs.
Future<void> showRowActions(
  BuildContext context, {
  required String title,
  VoidCallback? onComplete,
  VoidCallback? onSnooze,
  VoidCallback? onEdit,
  VoidCallback? onDelete,
}) {
  HapticFeedback.selectionClick();
  final l = context.l10n;
  return showMemoSheet<void>(
    context,
    builder: (sheet) {
      Widget row(String label, VoidCallback run, {bool destructive = false}) =>
          KeyValueRow(
            label: label,
            destructive: destructive,
            onTap: () {
              Navigator.of(sheet).pop();
              run();
            },
            child: const SizedBox.shrink(),
          );
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeading(title),
            SectionCard(
              children: [
                if (onComplete != null) row(l.commonMarkDone, onComplete),
                if (onSnooze != null) row(l.commonSnoozeTenMinutes, onSnooze),
                if (onEdit != null) row(l.commonEdit, onEdit),
                if (onDelete != null)
                  row(l.commonDelete, onDelete, destructive: true),
              ],
            ),
          ],
        ),
      );
    },
  );
}
