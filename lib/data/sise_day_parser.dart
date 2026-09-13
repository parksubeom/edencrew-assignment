import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../core/app_exception.dart';
import '../domain/daily_price.dart';
import 'dto/daily_price_page_dto.dart';

/// 일별 시세 HTML(`finance.naver.com/item/sise_day.naver`)을 파싱합니다.
///
/// 이 endpoint만 JSON이 아니라 HTML을 돌려주기 때문에, 파싱 규칙을 한곳에
/// 모아 두고 실제 HTML 조각으로 테스트할 수 있게 분리했습니다.
///
/// 표의 한 행은 다음과 같은 모양입니다.
///
/// ```html
/// <td align="center"><span class="tah p10 gray03">2026.09.11</span></td>
/// <td class="num"><span class="tah p11">259,500</span></td>
/// <td class="num">
///   <em class="bu_p bu_pdn"><span class="blind">하락</span></em>
///   <span class="tah p11 nv01">9,500</span>
/// </td>
/// ...
/// ```
abstract final class SiseDayParser {
  /// 표의 칸 순서입니다. `종가, 전일비, 시가, 고가, 저가, 거래량`
  static const int _dateIndex = 0;
  static const int _closeIndex = 1;
  static const int _changeIndex = 2;
  static const int _openIndex = 3;
  static const int _highIndex = 4;
  static const int _lowIndex = 5;
  static const int _volumeIndex = 6;

  static final RegExp _pageQuery = RegExp(r'page=(\d+)');
  static final RegExp _nonDigits = RegExp(r'[^0-9]');

  /// [page]는 어느 페이지를 요청해서 받은 HTML인지입니다. 마지막 페이지에는
  /// `맨뒤` 링크가 없어서, 그때 [DailyPricePageDto.lastPage]의 기본값으로 씁니다.
  static DailyPricePageDto parse(String body, {required int page}) {
    final dom.Document document;
    try {
      document = html_parser.parse(body);
    } catch (error) {
      throw StockDataException.parse(cause: error);
    }

    final List<DailyPrice> items = <DailyPrice>[];
    for (final dom.Element row in document.querySelectorAll('table.type2 tr')) {
      final DailyPrice? parsed = _parseRow(row);
      if (parsed != null) items.add(parsed);
    }

    return DailyPricePageDto(
      page: page,
      items: items,
      lastPage: _parseLastPage(document, fallback: page),
    );
  }

  /// 데이터 행이 아니면 null을 돌려줍니다.
  ///
  /// 표에는 헤더 행과 높이만 채우는 빈 행(`<td colspan="7" height="8">`)이
  /// 섞여 있어서, 칸 수와 날짜 모양으로 걸러냅니다.
  static DailyPrice? _parseRow(dom.Element row) {
    final List<dom.Element> cells = row.querySelectorAll('td');
    if (cells.length <= _volumeIndex) return null;

    final DateTime? date = _parseDate(cells[_dateIndex].text.trim());
    if (date == null) return null;

    final int close = _parseNumber(cells[_closeIndex].text);
    if (close == 0) return null;

    return DailyPrice(
      date: date,
      close: close,
      open: _parseNumber(cells[_openIndex].text),
      high: _parseNumber(cells[_highIndex].text),
      low: _parseNumber(cells[_lowIndex].text),
      volume: _parseNumber(cells[_volumeIndex].text),
      change: _parseChange(cells[_changeIndex]),
    );
  }

  /// `2026.09.11` → `DateTime(2026, 9, 11)`
  ///
  /// 시각은 쓰지 않으므로 자정으로 정규화합니다. (`yyyyMMdd` 기준으로
  /// 비교하기 위해서입니다.)
  static DateTime? _parseDate(String raw) {
    final List<String> parts = raw.split('.');
    if (parts.length != 3) return null;
    final int? year = int.tryParse(parts[0].trim());
    final int? month = int.tryParse(parts[1].trim());
    final int? day = int.tryParse(parts[2].trim());
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  /// `전일비` 칸을 부호 있는 등락액으로 바꿉니다.
  ///
  /// 숫자 자체는 절댓값이고 방향은 `<em>`의 class에만 들어 있습니다.
  /// `<span class="blind">`의 한글(상승/하락/보합) 대신 class를 보는 이유는,
  /// class가 문자 인코딩과 무관하게 안정적이기 때문입니다.
  static int _parseChange(dom.Element cell) {
    final int magnitude =
        _parseNumber(cell.querySelector('span.tah')?.text ?? cell.text);
    if (magnitude == 0) return 0;

    final String marker = cell.querySelector('em')?.className ?? '';
    if (marker.contains('bu_pup')) return magnitude;
    if (marker.contains('bu_pdn')) return -magnitude;
    return 0; // bu_pn — 보합
  }

  /// `259,500` · `\n\t\t9,500\n\t\t` → `259500` · `9500`
  static int _parseNumber(String raw) {
    final String digits = raw.replaceAll(_nonDigits, '');
    if (digits.isEmpty) return 0;
    return int.tryParse(digits) ?? 0;
  }

  /// 페이지 네비게이션의 `맨뒤` 링크(`<td class="pgRR">`)에서 마지막 페이지를
  /// 읽습니다. 마지막 페이지에는 이 링크가 없어 [fallback]을 씁니다.
  static int _parseLastPage(dom.Document document, {required int fallback}) {
    final String? href =
        document.querySelector('td.pgRR a')?.attributes['href'];
    if (href == null) return fallback;
    final Match? match = _pageQuery.firstMatch(href);
    if (match == null) return fallback;
    return int.tryParse(match.group(1)!) ?? fallback;
  }
}
