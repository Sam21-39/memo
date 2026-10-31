import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/app_version.dart';
import '../../core/chrome/chrome_mode.dart';
import '../../core/di.dart';
import '../../core/feature_flags/feature_flags.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/memo_nav_bar.dart';
import '../reminders/presentation/widgets/day_section_header.dart';
import '../reminders/presentation/widgets/key_value_row.dart';
import '../reminders/presentation/widgets/section_card.dart';
import 'settings_cubit.dart';

/// Artboard Settings. Rows for features not yet shipped stay hidden behind
/// their flags; Phase 2 is the one greyed forward reference.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    final flags = sl<FeatureFlags>();
    final cubit = context.read<SettingsCubit>();
    final glass = ChromeModeScope.of(context) == ChromeMode.glass;
    String allowed(bool? v) =>
        v == null ? '…' : (v ? 'Allowed' : 'Not allowed');

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) => Column(
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
                        'Settings',
                        style: MemoType.display.copyWith(color: c.ink),
                      ),
                    ),
                    const SizedBox(height: MemoSpace.space6),
                    const DaySectionHeader(label: 'Alarms'),
                    SectionCard(
                      children: [
                        KeyValueRow(
                          label: 'Notifications',
                          onTap: cubit.requestNotifications,
                          child: PillValue(
                            allowed(state.notifications),
                            active: state.notifications == true,
                          ),
                        ),
                        if (state.exactAlarms != null)
                          KeyValueRow(
                            label: 'Exact alarms',
                            onTap: cubit.requestExactAlarms,
                            child: PillValue(
                              allowed(state.exactAlarms),
                              active: state.exactAlarms == true,
                            ),
                          ),
                        if (flags.nag)
                          KeyValueRow(
                            label: 'Default nag',
                            child: PillValue(
                              state.defaultNagMin == null
                                  ? 'Off'
                                  : 'Every ${state.defaultNagMin} min',
                            ),
                          ),
                        if (flags.voiceCapture)
                          KeyValueRow(
                            label: 'Ring with my voice',
                            child: PillValue(
                              state.voiceRingsDefault ? 'On' : 'Off',
                              active: state.voiceRingsDefault,
                            ),
                          ),
                      ],
                    ),
                    if (state.notifications == false)
                      Padding(
                        padding: const EdgeInsets.only(top: MemoSpace.space2),
                        child: Text(
                          'Without this a reminder can be saved but never '
                          'heard.',
                          style: MemoType.body.copyWith(color: c.destructive),
                        ),
                      ),
                    if (flags.voiceCapture || flags.imageCapture) ...[
                      const SizedBox(height: MemoSpace.space6),
                      const DaySectionHeader(label: 'Capture'),
                      SectionCard(
                        children: [
                          if (flags.voiceCapture)
                            const KeyValueRow(
                              label: 'Dictation language',
                              child: PillValue('English'),
                            ),
                          if (flags.imageCapture)
                            const KeyValueRow(
                              label: 'Read photos on device',
                              child: PillValue('On', active: true),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: MemoSpace.space6),
                    const DaySectionHeader(label: 'Look'),
                    SectionCard(
                      children: [
                        const KeyValueRow(
                          label: 'Appearance',
                          child: PillValue('System'),
                        ),
                        KeyValueRow(
                          label: 'Glass chrome',
                          child: PillValue(
                            glass ? 'Follows iOS' : 'Solid',
                            active: glass,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MemoSpace.space6),
                    const DaySectionHeader(label: 'Phase 2'),
                    const Opacity(
                      opacity: 0.5,
                      child: SectionCard(
                        children: [
                          KeyValueRow(
                            label: 'Cloud sync',
                            child: PillValue('Soon'),
                          ),
                          KeyValueRow(
                            label: 'Shared reminders',
                            child: PillValue('Soon'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: MemoSpace.space6),
                    Text(
                      'Memō $appVersion · Nothing leaves this phone.',
                      style: MemoType.labelMedium.copyWith(color: c.ink70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
