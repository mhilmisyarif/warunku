import 'package:flutter/material.dart';

import '../models/debt_record.dart';
import '../utils/theme.dart';

class DebtStatusBadge extends StatelessWidget {
  const DebtStatusBadge(this.status, {super.key});

  final DebtStatus status;

  static Color colorOf(DebtStatus status) => switch (status) {
    DebtStatus.unpaid => AppTheme.danger,
    DebtStatus.partiallyPaid => AppTheme.warning,
    DebtStatus.paid => AppTheme.success,
  };

  @override
  Widget build(BuildContext context) {
    final color = colorOf(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
