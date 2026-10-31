import 'package:flutter/material.dart';

import '../chrome/memo_chrome.dart';
import '../theme/tokens.dart';

/// Bottom sheet on chrome: glass on iOS, solid elsewhere. Grabber, then the
/// caller's content. The list behind recedes under a dim.
Future<T?> showMemoSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool tall = false,
}) {
  final c = MemoColors.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: MemoColors.scrim,
    elevation: 0,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * (tall ? 0.9 : 0.75),
        ),
        child: MemoChrome(
          shape: ChromeShape.sheet,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                MemoSpace.gutter,
                MemoSpace.space3,
                MemoSpace.gutter,
                MemoSpace.gutter,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: MemoSpace.space4),
                      decoration: BoxDecoration(
                        color: c.ink45,
                        borderRadius: BorderRadius.circular(MemoRadius.pill),
                      ),
                    ),
                  ),
                  Flexible(child: builder(context)),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Title and one line of body for the top of a sheet.
class SheetHeading extends StatelessWidget {
  const SheetHeading(this.title, {super.key, this.body});

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: MemoType.title.copyWith(color: c.ink)),
        if (body != null) ...[
          const SizedBox(height: MemoSpace.space1),
          Text(body!, style: MemoType.body.copyWith(color: c.ink70)),
        ],
        const SizedBox(height: MemoSpace.space4),
      ],
    );
  }
}
