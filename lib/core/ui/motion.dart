import 'package:flutter/widgets.dart';

/// [d], or zero when the system asks for reduced motion.
Duration motion(BuildContext c, Duration d) =>
    MediaQuery.disableAnimationsOf(c) ? Duration.zero : d;
