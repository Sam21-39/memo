import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/ui/memo_nav_bar.dart';
import '../../core/utils/date_format.dart';
import '../../l10n/l10n.dart';
import '../reminders/presentation/widgets/section_card.dart';
import 'permission_status_row.dart';
import 'settings_cubit.dart';

/// Alarm health: one row per thing that decides whether a reminder rings.
class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  late final _lifecycle = AppLifecycleListener(
    onResume: () => context.read<SettingsCubit>().refresh(),
  );

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

  /// [n] of [total] counts only the items that need fixing.
  Future<void> _fix(HealthItem item, int n, int total) async {
    await context.push(
      '/settings/health/fix/${item.id}',
      extra: (n: n, total: total),
    );
    if (mounted) await context.read<SettingsCubit>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    final l = context.l10n;
    final cubit = context.read<SettingsCubit>();
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            final items = state.health;
            final broken = items.where((i) => i.needsFix).toList();
            final last = state.lastTestAt;
            return Column(
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
                      Semantics(
                        header: true,
                        child: Text(
                          l.healthTitle,
                          style: MemoType.display.copyWith(color: c.ink),
                        ),
                      ),
                      const SizedBox(height: MemoSpace.space3),
                      Text(
                        state.toFix == 0
                            ? l.healthBodyOk
                            : l.healthBodyFix(state.toFix),
                        style: MemoType.body.copyWith(color: c.ink70),
                      ),
                      const SizedBox(height: MemoSpace.space6),
                      SectionCard(
                        children: [
                          for (final i in items)
                            PermissionStatusRow(
                              title: healthItemTitle(l, i.id),
                              state: healthItemState(l, i),
                              status: i.status,
                              onTap: i.needsFix
                                  ? () => _fix(
                                      i,
                                      broken.indexOf(i) + 1,
                                      broken.length,
                                    )
                                  : null,
                            ),
                        ],
                      ),
                      const SizedBox(height: MemoSpace.space6),
                      if (broken.isNotEmpty) ...[
                        ElevatedButton(
                          onPressed: () => _fix(broken.first, 1, broken.length),
                          child: Text(
                            l.healthFixFirst(
                              healthItemTitle(l, broken.first.id),
                            ),
                          ),
                        ),
                        const SizedBox(height: MemoSpace.space3),
                      ],
                      OutlinedButton(
                        onPressed: cubit.ringTest,
                        child: Text(l.healthTestButton),
                      ),
                      if (state.testFailed) ...[
                        const SizedBox(height: MemoSpace.space3),
                        Text(
                          l.testFailed,
                          style: MemoType.body.copyWith(color: c.accentText),
                        ),
                      ] else if (last != null) ...[
                        const SizedBox(height: MemoSpace.space3),
                        Text(
                          l.healthLastTest(
                            isSameDay(last, DateTime.now())
                                ? formatTime(context, last)
                                : formatWhen(context, last, DateTime.now()),
                          ),
                          style: MemoType.body.copyWith(color: c.ink70),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
