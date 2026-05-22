import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class HashtagUtils {
  static final _regex = RegExp(r'#(\w+)');

  static List<String> extract(String text) =>
      _regex.allMatches(text).map((m) => m.group(1)!.toLowerCase()).toList();

  static String normalize(String tag) =>
      tag.replaceAll('#', '').toLowerCase().trim();

  static List<String> extractNormalized(String text) =>
      extract(text).map(normalize).toSet().toList();

  static List<InlineSpan> buildRichSpans(
    String text, {
    TextStyle? baseStyle,
    TextStyle? hashtagStyle,
    void Function(String tag)? onTap,
  }) {
    final spans = <InlineSpan>[];
    int last = 0;
    for (final match in _regex.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(
          text: text.substring(last, match.start),
          style: baseStyle,
        ));
      }
      final tag = match.group(0)!;
      spans.add(WidgetSpan(
        child: GestureDetector(
          onTap: onTap != null ? () => onTap(match.group(1)!) : null,
          child: Text(
            tag,
            style: hashtagStyle ??
                const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ));
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last), style: baseStyle));
    }
    return spans;
  }
}
