import 'package:flutter/material.dart';

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
      effectiveSuffix = const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          width: 16,
          height: 16,
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
          color: hasError ? const Color(0xFFE53935) : Colors.grey,
        ),
      );
    } else if (isValid && !hasError) {
      effectiveSuffix = const Icon(
        Icons.check_circle_rounded,
        color: Color(0xFF2E7D32),
        size: 20,
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
            borderRadius: BorderRadius.circular(12),
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
            onChanged: onChanged,
            decoration: InputDecoration(
              labelText: requiredMark ? '$labelText *' : labelText,
              labelStyle: TextStyle(
                color: hasError
                    ? const Color(0xFFE53935)
                    : (isValid ? const Color(0xFF2E7D32) : Colors.grey[700]),
              ),
              hintText: hintText,
              prefixIcon: prefixIcon != null
                  ? Icon(
                      prefixIcon,
                      color: hasError
                          ? const Color(0xFFE53935)
                          : (isValid ? const Color(0xFF2E7D32) : Colors.grey),
                    )
                  : null,
              suffixIcon: effectiveSuffix,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 14,
                    color: Color(0xFFE53935),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    errorText!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFE53935),
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
