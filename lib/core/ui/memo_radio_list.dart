import 'package:flutter/material.dart';

import '../../features/reminders/presentation/widgets/section_card.dart';
import '../theme/tokens.dart';

class MemoRadioOption<T> {
  const MemoRadioOption(
    this.value,
    this.title, {
    this.hint,
    this.enabled = true,
  });

  final T value;
  final String title;
  final String? hint;
  final bool enabled;
}

/// One-of-many list on a [SectionCard]: ring and dot on the left, title and
/// optional hint beside it.
class MemoRadioList<T> extends StatelessWidget {
  const MemoRadioList({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<MemoRadioOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    return SectionCard(
      children: [
        for (final o in options)
          Semantics(
            inMutuallyExclusiveGroup: true,
            checked: o.value == value,
            button: true,
            enabled: o.enabled,
            child: InkWell(
              onTap: o.enabled ? () => onChanged(o.value) : null,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MemoSpace.space4,
                    vertical: MemoSpace.space2,
                  ),
                  child: Opacity(
                    opacity: o.enabled ? 1 : 0.5,
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: o.value == value ? c.ink : c.ink70,
                              width: 1.5,
                            ),
                          ),
                          child: o.value == value
                              ? Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: c.ink,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: MemoSpace.space3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                o.title,
                                style: MemoType.bodyLarge.copyWith(
                                  color: c.ink,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              if (o.hint != null)
                                Text(
                                  o.hint!,
                                  style: MemoType.body.copyWith(
                                    color: c.ink70,
                                    fontSize: 13,
                                    height: 18 / 13,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
