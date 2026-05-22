import 'package:flutter/material.dart';

class TickerUtils {
  static final _regex = RegExp(r'\$([A-Za-z][A-Za-z0-9]{0,7})');

  static List<String> extract(String text) =>
      _regex.allMatches(text).map((m) => m.group(1)!.toUpperCase()).toList();

  static List<String> extractNormalized(String text) =>
      extract(text).toSet().toList();

  static List<InlineSpan> buildRichSpans(
    String text, {
    TextStyle? baseStyle,
    void Function(String ticker)? onTap,
  }) {
    const tickerStyle = TextStyle(
      color: Color(0xFF22C55E),
      fontWeight: FontWeight.w700,
    );
    final spans = <InlineSpan>[];
    int last = 0;
    for (final match in _regex.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start), style: baseStyle));
      }
      final raw = match.group(0)!;
      final ticker = match.group(1)!.toUpperCase();
      spans.add(WidgetSpan(
        child: GestureDetector(
          onTap: onTap != null ? () => onTap(ticker) : null,
          child: Text(raw, style: tickerStyle.merge(baseStyle?.copyWith(color: null, fontWeight: null))),
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
