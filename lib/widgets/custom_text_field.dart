import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final String labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconTap;
  final Widget? suffixWidget;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final String? errorText;
  final bool isValid;
  final bool isValidating;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final bool requiredMark;
  final TextInputAction? textInputAction;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool compact;

  const CustomTextField({
    super.key,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.suffixWidget,
    this.obscureText = false,
    this.keyboardType,
    this.controller,
    this.errorText,
    this.isValid = false,
    this.isValidating = false,
    this.onChanged,
    this.focusNode,
    this.requiredMark = false,
    this.textInputAction,
    this.maxLength,
    this.inputFormatters,
    this.readOnly = false,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    Color borderColor = Colors.transparent;
    if (hasError) {
      borderColor = const Color(0xFFE53935);
    } else if (isValid) {
      borderColor = const Color(0xFF2E7D32);
    }

    Widget? effectiveSuffix;
    if (isValidating) {
      effectiveSuffix = Padding(
        padding: EdgeInsets.all(compact ? 10 : 14),
        child: const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFFB9833),
          ),
        ),
      );
    } else if (suffixWidget != null) {
      effectiveSuffix = suffixWidget;
    } else if (suffixIcon != null) {
      effectiveSuffix = GestureDetector(
        onTap: onSuffixIconTap,
        child: Icon(
          suffixIcon,
          size: compact ? 18 : 22,
          color: hasError ? const Color(0xFFE53935) : Colors.grey,
        ),
      );
    } else if (isValid && !hasError) {
      effectiveSuffix = Icon(
        Icons.check_circle_rounded,
        color: const Color(0xFF2E7D32),
        size: compact ? 16 : 20,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4F8),
            borderRadius: BorderRadius.circular(compact ? 10 : 12),
            border: Border.all(
              color: borderColor,
              width: (hasError || isValid) ? 1.5 : 0.0,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            readOnly: readOnly,
            onTap: onTap,
            onChanged: onChanged,
            style: TextStyle(fontSize: compact ? 13 : 14.5),
            decoration: InputDecoration(
              counterText: '',
              isDense: compact,
              labelText: requiredMark ? '$labelText *' : labelText,
              labelStyle: TextStyle(
                fontSize: compact ? 12 : 14,
                color: hasError
                    ? const Color(0xFFE53935)
                    : (isValid ? const Color(0xFF2E7D32) : Colors.grey[700]),
              ),
              hintText: hintText,
              hintStyle: TextStyle(fontSize: compact ? 12 : 14),
              prefixIcon: prefixIcon != null
                  ? Icon(
                      prefixIcon,
                      size: compact ? 18 : 22,
                      color: hasError
                          ? const Color(0xFFE53935)
                          : (isValid ? const Color(0xFF2E7D32) : Colors.grey),
                    )
                  : null,
              prefixIconConstraints: compact
                  ? const BoxConstraints(minWidth: 36, minHeight: 36)
                  : null,
              suffixIcon: effectiveSuffix,
              suffixIconConstraints: compact
                  ? const BoxConstraints(minWidth: 34, minHeight: 36)
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 16,
                vertical: compact ? 9 : 14,
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: EdgeInsets.only(top: compact ? 2 : 4, left: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 12,
                    color: Color(0xFFE53935),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    errorText!,
                    style: TextStyle(
                      fontSize: compact ? 10.5 : 12,
                      color: const Color(0xFFE53935),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
