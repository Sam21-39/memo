import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/feature_flags/feature_flags.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/key_value_row.dart';
import '../widgets/section_card.dart';

/// memo Screens E · settings. v1 shows what is on, plus the single greyed
/// "Phase 2" row — the only forward reference in the UI.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _flags = sl<FeatureFlags>();
  bool? _notificationsGranted;

  @override
  void initState() {
    super.initState();
    _refreshPermission();
  }

  Future<void> _refreshPermission() async {
    final granted = await Permission.notification.isGranted;
    if (mounted) setState(() => _notificationsGranted = granted);
  }

  Future<void> _requestOrOpenSettings() async {
    if (_notificationsGranted == true) {
      await openAppSettings();
    } else {
      await Permission.notification.request();
    }
    await _refreshPermission();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final granted = _notificationsGranted;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        title: Text('Settings', style: theme.textTheme.titleLarge),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenGutter,
            AppSpacing.sm,
            AppSpacing.screenGutter,
            AppSpacing.xxl,
          ),
          children: [
            Text('Alerts'.toUpperCase(), style: theme.textTheme.labelSmall),
            const SizedBox(height: AppSpacing.sm),
            SectionCard(
              children: [
                KeyValueRow(
                  label: 'Notifications',
                  onTap: _requestOrOpenSettings,
                  child: Text(
                    granted == null
                        ? '…'
                        : (granted ? 'Allowed' : 'Not allowed'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontSize: 14,
                      color: granted == false
                          ? scheme.primary
                          : scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
            if (granted == false)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  'Without this a reminder can be saved but never heard.',
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            Text('Features'.toUpperCase(), style: theme.textTheme.labelSmall),
            const SizedBox(height: AppSpacing.sm),
            SectionCard(
              children: [
                _FlagRow(label: 'Repeat', enabled: _flags.repeatReminders),
                _FlagRow(label: 'Snooze', enabled: _flags.snooze),
                _FlagRow(label: 'Tags', enabled: _flags.tags),
                const _FlagRow(
                  label: 'Cloud sync',
                  enabled: false,
                  detail: 'Phase 2',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FlagRow extends StatelessWidget {
  const _FlagRow({required this.label, required this.enabled, this.detail});

  final String label;
  final bool enabled;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final greyed = detail != null;

    return Opacity(
      opacity: greyed ? 0.45 : 1,
      child: KeyValueRow(
        label: label,
        child: Text(
          detail ?? (enabled ? 'On' : 'Off'),
          style: theme.textTheme.labelMedium?.copyWith(
            fontSize: 14,
            color: scheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
