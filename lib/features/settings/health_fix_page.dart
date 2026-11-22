import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/ui/memo_nav_bar.dart';
import '../../l10n/l10n.dart';
import '../reminders/presentation/widgets/section_card.dart';
import 'permission_status_row.dart';
import 'settings_cubit.dart';

/// One remediation: what is wrong, numbered steps, a button to the system
/// screen, and "check again". Moves on by itself once the item is fixed.
class HealthFixPage extends StatefulWidget {
  const HealthFixPage({super.key, required this.id, this.step});

  final String id;

  /// "Fix n of total"; counted from the items needing a fix when null.
  final ({int n, int total})? step;

  @override
  State<HealthFixPage> createState() => _HealthFixPageState();
}

class _HealthFixPageState extends State<HealthFixPage> {
  late final _lifecycle = AppLifecycleListener(
    onResume: () => context.read<SettingsCubit>().refresh(),
  );
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _lifecycle;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _advance(SettingsState state) {
    // Not read yet: nothing to judge.
    if (_left || !(state.android || state.ios)) return;
    final items = state.health;
    if (items.where((i) => i.id == widget.id).any((i) => i.needsFix)) return;
    _left = true;
    final left = items.where((i) => i.needsFix).toList();
    final next = left.firstOrNull;
    if (next == null) {
      context.pop();
    } else {
      final s = widget.step;
      context.pushReplacement(
        '/settings/health/fix/${next.id}',
        extra: s == null
            ? null
            : (
                n: (s.total - left.length + 1).clamp(1, s.total),
                total: s.total,
              ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    final l = context.l10n;
    final cubit = context.read<SettingsCubit>();
    return BlocConsumer<SettingsCubit, SettingsState>(
      listener: (_, state) => _advance(state),
      builder: (context, state) {
        final broken = state.health.where((i) => i.needsFix).toList();
        final at = broken.indexWhere((i) => i.id == widget.id);
        final step =
            widget.step ??
            (n: at < 0 ? 1 : at + 1, total: broken.isEmpty ? 1 : broken.length);
        final steps = healthItemSteps(l, widget.id);
        return Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const MemoNavBar(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      MemoSpace.gutter,
                      MemoSpace.space6,
                      MemoSpace.gutter,
                      MemoSpace.space8,
                    ),
                    children: [
                      Text(
                        l.healthFixStep(step.n, step.total),
                        style: MemoType.labelMedium.copyWith(color: c.ink70),
                      ),
                      const SizedBox(height: MemoSpace.space2),
                      Semantics(
                        header: true,
                        child: Text(
                          healthItemTitle(l, widget.id),
                          style: MemoType.display.copyWith(color: c.ink),
                        ),
                      ),
                      const SizedBox(height: MemoSpace.space3),
                      Text(
                        healthItemBody(l, widget.id),
                        style: MemoType.body.copyWith(color: c.ink70),
                      ),
                      const SizedBox(height: MemoSpace.space6),
                      SectionCard(
                        children: [
                          for (var i = 1; i <= steps.length; i++)
                            Padding(
                              padding: const EdgeInsets.all(MemoSpace.space4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$i',
                                    style: MemoType.labelMedium.copyWith(
                                      color: c.ink70,
                                    ),
                                  ),
                                  const SizedBox(width: MemoSpace.space3),
                                  Expanded(
                                    child: Text(
                                      steps[i - 1],
                                      style: MemoType.bodyLarge.copyWith(
                                        color: c.ink,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (state.android && state.maker.isNotEmpty) ...[
                        const SizedBox(height: MemoSpace.space3),
                        Text(
                          l.healthDetected(state.maker),
                          style: MemoType.body.copyWith(color: c.ink70),
                        ),
                      ],
                      const SizedBox(height: MemoSpace.space6),
                      ElevatedButton(
                        onPressed: () => cubit.fix(widget.id),
                        child: Text(
                          widget.id == 'battery'
                              ? l.healthOpenBattery
                              : l.healthOpenSettings,
                        ),
                      ),
                      const SizedBox(height: MemoSpace.space3),
                      OutlinedButton(
                        onPressed: cubit.refresh,
                        child: Text(l.healthCheckAgain),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
