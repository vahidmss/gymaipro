import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GoldButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool loading;

  const GoldButton(
      {required this.text,
      required this.onPressed,
      this.loading = false,
      super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 350),
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          backgroundColor: AppTheme.goldColor,
          foregroundColor: Colors.black,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          textStyle: AppTheme.subheadingStyle
              .copyWith(fontSize: 18, color: Colors.black),
        ),
        child: loading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    color: Colors.black, strokeWidth: 2))
            : Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }
}
