import 'package:flutter/material.dart';

import '../models/customer.dart';

/// Initial on a soft colour picked from the name, so rows are easy to scan.
class CustomerAvatar extends StatelessWidget {
  const CustomerAvatar(this.customer, {super.key, this.radius = 22});

  final Customer customer;
  final double radius;

  static const _palette = [
    Color(0xFF0E7C66),
    Color(0xFF2F80ED),
    Color(0xFF9B51E0),
    Color(0xFFE08A1E),
    Color(0xFFD64545),
    Color(0xFF0E9AA7),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _palette[customer.name.hashCode.abs() % _palette.length];
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.14),
      child: Text(
        customer.initial,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}
