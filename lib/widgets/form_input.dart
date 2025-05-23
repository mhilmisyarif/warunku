import 'package:flutter/material.dart';

class FormInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const FormInput({required this.label, required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
