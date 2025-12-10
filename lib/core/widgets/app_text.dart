// lib/widgets/app_text.dart
import 'package:flutter/material.dart';

class AppText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AppText(
      this.text, {
        super.key,
        this.style,
        this.textAlign,
        this.maxLines,
        this.overflow,
      });

  factory AppText.heading(String text, BuildContext context) {
    final theme = Theme.of(context);
    return AppText(
      text,
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
      textAlign: TextAlign.center,
    );
  }

  factory AppText.subtitle(String text, BuildContext context) {
    final theme = Theme.of(context);
    return AppText(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: Colors.grey.shade600,
      ),
      textAlign: TextAlign.center,
    );
  }

  factory AppText.link(String text, BuildContext context) {
    final theme = Theme.of(context);
    return AppText(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: const Color(0xFF1A73E8),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
