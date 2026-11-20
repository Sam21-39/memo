import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../../l10n/strings.dart';

/// Two-action confirm. iOS: a Cupertino alert. Android: a Material dialog
/// (radius 28, right-aligned text actions). Returns true when confirmed.
/// Two actions maximum; a third means it should be a sheet.
Future<bool> showMemoConfirm(
  BuildContext context, {
  required String title,
  required String body,
  required String confirm,
  bool destructive = false,
}) async {
  final c = MemoColors.of(context);
  final confirmColor = destructive ? c.destructive : c.accentText;
  final ios = Theme.of(context).platform == TargetPlatform.iOS;
  final result = ios
      ? await showCupertinoDialog<bool>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(S.commonCancel),
              ),
              CupertinoDialogAction(
                isDestructiveAction: destructive,
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(confirm),
              ),
            ],
          ),
        )
      : await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(foregroundColor: c.ink),
                child: const Text(S.commonCancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: confirmColor),
                child: Text(confirm),
              ),
            ],
          ),
        );
  return result ?? false;
}
