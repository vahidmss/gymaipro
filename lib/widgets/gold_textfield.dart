import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GoldTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;
  final bool enabled;
  final void Function(String)? onChanged;

  const GoldTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.enabled = true,
    this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 350),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          obscureText: obscureText,
          enabled: enabled,
          onChanged: onChanged,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          decoration: AppTheme.textFieldDecoration(label, hint: hint).copyWith(
            suffixIcon: suffixIcon,
          ),
        ),
      ),
    );
  }
}
