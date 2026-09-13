import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

/// 종목명에서 검색어와 일치하는 부분을 `searchHighlight` 색으로 칠합니다.
///
/// 한 번만 칠하지 않고 **일치하는 곳을 모두** 칠합니다. `한국전력 · 한국가스`
/// 처럼 같은 글자가 여러 번 나오는 이름에서 앞부분만 칠해지면, 왜 칠해졌는지
/// 기준이 없어 보이기 때문입니다.
class HighlightedName extends StatelessWidget {
  const HighlightedName({
    required this.name,
    required this.query,
    required this.style,
    super.key,
  });

  final String name;

  /// 사용자가 입력한 검색어입니다. 비어 있으면 칠하지 않습니다.
  final String query;

  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: buildSpans(
          name: name,
          query: query,
          highlightColor: context.colors.searchHighlight,
        ),
      ),
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 대소문자를 무시하고 [query]가 나오는 구간을 찾아 스팬으로 쪼갭니다.
  ///
  /// 종목코드로 검색했을 때는 이름에 일치하는 부분이 없어 통째로 한 스팬이
  /// 됩니다. (그때는 아래 줄의 종목코드가 곧 검색 결과의 근거가 됩니다.)
  @visibleForTesting
  static List<TextSpan> buildSpans({
    required String name,
    required String query,
    required Color highlightColor,
  }) {
    final String needle = query.trim();
    if (needle.isEmpty) return <TextSpan>[TextSpan(text: name)];

    final String haystackLower = name.toLowerCase();
    final String needleLower = needle.toLowerCase();

    final List<TextSpan> spans = <TextSpan>[];
    int cursor = 0;

    while (cursor < name.length) {
      final int matchStart = haystackLower.indexOf(needleLower, cursor);
      if (matchStart < 0) {
        spans.add(TextSpan(text: name.substring(cursor)));
        break;
      }

      if (matchStart > cursor) {
        spans.add(TextSpan(text: name.substring(cursor, matchStart)));
      }
      final int matchEnd = matchStart + needle.length;
      spans.add(
        TextSpan(
          text: name.substring(matchStart, matchEnd),
          style: TextStyle(color: highlightColor),
        ),
      );
      cursor = matchEnd;
    }

    return spans;
  }
}
