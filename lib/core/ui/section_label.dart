import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// label-small is uppercase and tracked for Latin only; Devanagari and Bengali
/// have no case and tracking breaks conjuncts.
bool _latin(BuildContext c) =>
    (Localizations.maybeLocaleOf(c)?.languageCode ?? 'en') == 'en';

String sectionLabelText(BuildContext c, String s) =>
    _latin(c) ? s.toUpperCase() : s;

TextStyle sectionLabelStyle(BuildContext c) => _latin(c)
    ? MemoType.labelSmall
    : MemoType.body.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 18 / 13,
      );
