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
  final bool darkTheme;

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
    this.darkTheme = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;
    final hasFocus = focusNode?.hasFocus ?? false;

    final Color errorColor =
        darkTheme ? const Color(0xFFF43F5E) : const Color(0xFFE53935);
    final Color validColor =
        darkTheme ? const Color(0xFF10B981) : const Color(0xFF2E7D32);
    const Color accentOrange = Color(0xFFFB9833);
    const Color petrolLight = Color(0xFF1B768E);

    Color borderColor = darkTheme
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.transparent;
    double borderWidth = darkTheme ? 1.1 : 0.0;

    if (hasError) {
      borderColor = errorColor;
      borderWidth = 1.5;
    } else if (darkTheme && hasFocus) {
      borderColor = accentOrange;
      borderWidth = 1.5;
    } else if (isValid) {
      borderColor = darkTheme
          ? validColor.withValues(alpha: 0.75)
          : validColor;
      borderWidth = 1.4;
    }

    Color iconColor = darkTheme ? petrolLight : Colors.grey;
    if (hasError) {
      iconColor = errorColor;
    } else if (darkTheme && hasFocus) {
      iconColor = accentOrange;
    } else if (isValid) {
      iconColor = validColor;
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
            color: accentOrange,
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
          color: hasError
              ? errorColor
              : (darkTheme
                  ? Colors.white.withValues(alpha: 0.55)
                  : Colors.grey),
        ),
      );
    } else if (isValid && !hasError) {
      effectiveSuffix = Icon(
        Icons.check_circle_rounded,
        color: validColor,
        size: compact ? 16 : 20,
      );
    }

    // Modo oscuro con estilo limpio y etiquetas externas alineadas (igual al Login)
    if (darkTheme) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 5),
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'Arial',
                  fontSize: compact ? 10.5 : 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Colors.white.withValues(alpha: 0.74),
                ),
                children: [
                  TextSpan(text: labelText.toUpperCase()),
                  if (requiredMark)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: accentOrange,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: compact ? 42 : 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF041722),
              borderRadius: BorderRadius.circular(compact ? 11 : 14),
              border: Border.all(
                color: borderColor,
                width: borderWidth,
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
              cursorColor: accentOrange,
              style: TextStyle(
                fontSize: compact ? 13 : 14.5,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                counterText: '',
                isDense: true,
                hintText: hintText ?? labelText,
                hintStyle: TextStyle(
                  fontSize: compact ? 12.5 : 14,
                  color: Colors.white.withValues(alpha: 0.34),
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: prefixIcon != null
                    ? Icon(
                        prefixIcon,
                        size: compact ? 17 : 20,
                        color: iconColor,
                      )
                    : null,
                prefixIconConstraints: BoxConstraints(
                  minWidth: compact ? 36 : 42,
                  minHeight: compact ? 40 : 46,
                ),
                suffixIcon: effectiveSuffix,
                suffixIconConstraints: BoxConstraints(
                  minWidth: compact ? 34 : 40,
                  minHeight: compact ? 40 : 46,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 14,
                  vertical: compact ? 10 : 12,
                ),
              ),
            ),
          ),
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 11.5,
                      color: errorColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      errorText!,
                      style: TextStyle(
                        fontSize: compact ? 10.5 : 11.5,
                        color: errorColor,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    // Modo claro predeterminado para otras pantallas de la app
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4F8),
            borderRadius: BorderRadius.circular(compact ? 12 : 14),
            border: Border.all(
              color: borderColor,
              width: borderWidth,
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
            style: TextStyle(
              fontSize: compact ? 13 : 14.5,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              counterText: '',
              isDense: compact,
              labelText: requiredMark ? '$labelText *' : labelText,
              labelStyle: TextStyle(
                fontSize: compact ? 12 : 14,
                color: hasError
                    ? errorColor
                    : (isValid ? validColor : Colors.grey[700]),
              ),
              hintText: hintText,
              hintStyle: TextStyle(fontSize: compact ? 12 : 14),
              prefixIcon: prefixIcon != null
                  ? Icon(
                      prefixIcon,
                      size: compact ? 18 : 22,
                      color: iconColor,
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
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 12,
                    color: errorColor,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    errorText!,
                    style: TextStyle(
                      fontSize: compact ? 10.5 : 12,
                      color: errorColor,
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
