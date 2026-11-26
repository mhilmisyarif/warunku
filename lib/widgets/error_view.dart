import 'package:flutter/material.dart';

import '../utils/theme.dart';

/// Full-screen error message with a retry button.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyView(
      icon: Icons.wifi_off_rounded,
      message: message,
      action: FilledButton.tonalIcon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Coba lagi'),
      ),
    );
  }
}

/// Centered icon + message, used for empty lists and errors.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: scheme.primary.withValues(alpha: 0.08),
              child: Icon(icon, size: 34, color: scheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              SizedBox(width: 160, child: action),
            ],
          ],
        ),
      ),
    );
  }
}

/// Primary action pinned above the keyboard/bottom inset, optionally with a
/// summary line (e.g. a running total) above the button.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child, this.summary});

  final Widget child;
  final Widget? summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.outline)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (summary != null) ...[summary!, const SizedBox(height: 10)],
            child,
          ],
        ),
      ),
    );
  }
}

/// Shows a floating success (green) or failure (red) message.
void showResultSnackBar(
  ScaffoldMessengerState messenger,
  String message, {
  bool success = true,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppTheme.success : AppTheme.danger,
      ),
    );
}
