import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymaipro/utils/text_controller_utils.dart';

/// یک TextFormField ایمن که بررسی می‌کند controller dispose نشده است
class SafeTextFormField extends StatefulWidget {
  const SafeTextFormField({
    required this.controller,
    this.focusNode,
    this.style,
    this.decoration,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.textInputAction,
    this.keyboardType,
    this.maxLines,
    this.minLines,
    this.textDirection,
    this.enabled,
    this.autofocus,
    this.obscureText,
    this.maxLength,
    this.maxLengthEnforcement,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextStyle? style;
  final InputDecoration? decoration;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? minLines;
  final TextDirection? textDirection;
  final bool? enabled;
  final bool? autofocus;
  final bool? obscureText;
  final int? maxLength;
  final MaxLengthEnforcement? maxLengthEnforcement;

  @override
  State<SafeTextFormField> createState() => _SafeTextFormFieldState();
}

class _SafeTextFormFieldState extends State<SafeTextFormField> {
  bool _shouldRender = true;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    // بررسی اولیه
    try {
      _shouldRender = widget.controller.isSafe;
    } catch (e) {
      _shouldRender = false;
    }
  }

  @override
  void didUpdateWidget(SafeTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // بررسی مجدد در هر update
    if (mounted && !_isDisposed) {
      try {
        final isSafe = widget.controller.isSafe;
        if (_shouldRender != isSafe) {
          setState(() {
            _shouldRender = isSafe;
          });
        }
      } catch (e) {
        if (_shouldRender) {
          setState(() {
            _shouldRender = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _shouldRender = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // اگر state dispose شده، هیچ چیز render نکن
    if (_isDisposed || !mounted) {
      return const SizedBox.shrink();
    }

    // بررسی مجدد در هر build
    bool isSafe = false;
    try {
      isSafe = widget.controller.isSafe;
    } catch (e) {
      isSafe = false;
    }

    // اگر controller dispose شده، TextField را کاملاً حذف می‌کنیم
    if (!isSafe || !_shouldRender) {
      return const SizedBox.shrink();
    }

    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      style: widget.style,
      decoration: widget.decoration,
      inputFormatters: widget.inputFormatters,
      validator: widget.validator,
      onChanged: widget.onChanged != null
          ? (value) {
              // بررسی مجدد قبل از فراخوانی callback
              if (mounted && !_isDisposed) {
                try {
                  if (widget.controller.isSafe) {
                    widget.onChanged!(value);
                  }
                } catch (e) {
                  // Controller disposed, ignore
                }
              }
            }
          : null,
      onFieldSubmitted: widget.onFieldSubmitted != null
          ? (value) {
              // بررسی مجدد قبل از فراخوانی callback
              if (mounted && !_isDisposed) {
                try {
                  if (widget.controller.isSafe) {
                    widget.onFieldSubmitted!(value);
                  }
                } catch (e) {
                  // Controller disposed, ignore
                }
              }
            }
          : null,
      textInputAction: widget.textInputAction,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      textDirection: widget.textDirection,
      enabled: widget.enabled,
      autofocus: widget.autofocus ?? false,
      obscureText: widget.obscureText ?? false,
      maxLength: widget.maxLength,
      maxLengthEnforcement: widget.maxLengthEnforcement,
    );
  }
}
