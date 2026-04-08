import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

class ATextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText; // Changed from isPassword for compatibility
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final TextInputAction? textInputAction;

  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLength;
  final List<dynamic>? inputFormatters;

  const ATextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.autofocus = false,
    this.textInputAction,
    this.style,
    this.textAlign = TextAlign.start,
    this.maxLength,
    this.inputFormatters,
  });

  @override
  State<ATextField> createState() => _ATextFieldState();
}

class _ATextFieldState extends State<ATextField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              widget.label!,
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
        Focus(
          onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              // Modern "Deep Dark" surface
              color: _isFocused 
                  ? const Color(0xFF121220) 
                  : const Color(0xFF0A0A0F),
              borderRadius: BorderRadius.circular(24),
              // Floating border effect
              border: Border.all(
                color: _isFocused 
                    ? AColors.primary.withValues(alpha: 0.5) 
                    : Colors.white.withValues(alpha: 0.08),
                width: 1.5,
              ),
              boxShadow: _isFocused ? [
                BoxShadow(
                  color: AColors.primary.withValues(alpha: 0.15),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ] : [],
            ),
            child: TextField(
              controller: widget.controller,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              autofocus: widget.autofocus,
              textInputAction: widget.textInputAction,
              onChanged: widget.onChanged,
              cursorColor: AColors.primary,
              textAlign: widget.textAlign,
              maxLength: widget.maxLength,
              inputFormatters: widget.inputFormatters != null ? List<TextInputFormatter>.from(widget.inputFormatters!) : null,
              style: widget.style ?? GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                counterText: "", // Hide character counter
                hintStyle: GoogleFonts.outfit(
                  color: Colors.white.withValues(alpha: 0.25),
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: widget.prefixIcon != null ? Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: IconTheme(
                    data: IconThemeData(
                      color: _isFocused ? AColors.primary : Colors.white.withValues(alpha: 0.2),
                      size: 20,
                    ),
                    child: widget.prefixIcon!,
                  ),
                ) : null,
                suffixIcon: widget.suffixIcon != null ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconTheme(
                    data: IconThemeData(
                      color: _isFocused ? AColors.primary : Colors.white.withValues(alpha: 0.2),
                      size: 20,
                    ),
                    child: widget.suffixIcon!,
                  ),
                ) : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
