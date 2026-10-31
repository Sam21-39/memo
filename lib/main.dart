import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/di.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const MemoApp());
}
