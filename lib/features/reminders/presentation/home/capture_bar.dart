import 'package:flutter/material.dart';

import '../../../../core/chrome/memo_chrome.dart';
import '../../../../core/di.dart';
import '../../../../core/feature_flags/feature_flags.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/ui/memo_nav_bar.dart';

/// The floating bar over Home, in its idle state: placeholder, camera, mic.
/// A canvas fade sits beneath it so the list disappears rather than ends.
///
/// M0: tapping the field opens the edit sheet. M2 turns it into a live text
/// field with parsed chips, and the mic into hold-to-record.
class CaptureBar extends StatelessWidget {
  const CaptureBar({super.key, required this.onCompose});

  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    final flags = sl<FeatureFlags>();
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, 0.6],
            colors: [c.canvas.withValues(alpha: 0), c.canvas],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            MemoSpace.space3,
            MemoSpace.space6,
            MemoSpace.space3,
            MediaQuery.paddingOf(context).bottom + MemoSpace.space3,
          ),
          child: MemoChrome(
            shape: ChromeShape.bar,
            child: SizedBox(
              height: MemoSpace.barHeight,
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'New reminder',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onCompose,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: MemoSpace.space4,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Remind me to…',
                              style: MemoType.bodyLarge.copyWith(
                                color: c.ink45,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (flags.imageCapture)
                    const MemoIconButton(
                      icon: Icons.photo_camera_outlined,
                      label: 'Add a photo',
                    ),
                  if (flags.voiceCapture)
                    const MemoIconButton(
                      icon: Icons.mic_none_rounded,
                      label: 'Hold to record',
                      accent: true,
                    ),
                  const SizedBox(width: MemoSpace.space1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
