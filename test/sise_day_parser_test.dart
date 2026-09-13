import 'dart:io';

import 'package:charset/charset.dart';
import 'package:edencrew_assignment_starter/data/dto/daily_price_page_dto.dart';
import 'package:edencrew_assignment_starter/data/sise_day_parser.dart';
import 'package:edencrew_assignment_starter/domain/daily_price.dart';
import 'package:edencrew_assignment_starter/domain/price_direction.dart';
import 'package:flutter_test/flutter_test.dart';

/// 일별 시세 HTML 파싱은 이 과제에서 가장 깨지기 쉬운 부분이라, 저장해 둔
/// 실제 응답으로 확인합니다.
void main() {
  late DailyPricePageDto page;

  setUpAll(() async {
    final String html = eucKr.decode(
      await File('assets/mock/sise_day_005930_p1.html').readAsBytes(),
    );
    page = SiseDayParser.parse(html, page: 1);
  });

  test('한 페이지에 10거래일이 들어 있다', () {
    expect(page.items, hasLength(10));
  });

  test('헤더 행과 빈 행은 걸러진다', () {
    // 표에는 <th> 행과 높이만 채우는 <td colspan="7"> 행이 섞여 있습니다.
    for (final DailyPrice price in page.items) {
      expect(price.close, greaterThan(0));
      expect(price.volume, greaterThan(0));
    }
  });

  test('첫 행의 값이 표와 일치한다', () {
    final DailyPrice first = page.items.first;

    expect(first.date, DateTime(2026, 9, 11));
    expect(first.close, 259500);
    expect(first.open, 258000);
    expect(first.high, 261500);
    expect(first.low, 256500);
    expect(first.volume, 13938673);
  });

  test('전일비의 부호를 em class로 판정한다', () {
    // 첫 행은 `bu_pdn`(하락)이므로 절댓값 9,500에 음수 부호가 붙어야 합니다.
    final DailyPrice first = page.items.first;
    expect(first.change, -9500);
    expect(first.direction, PriceDirection.down);

    // 보합(`bu_pn`) 행은 0이어야 합니다.
    final DailyPrice flat = page.items.firstWhere(
      (DailyPrice price) => price.date == DateTime(2026, 9, 9),
    );
    expect(flat.change, 0);
    expect(flat.direction, PriceDirection.flat);

    // 상승(`bu_pup`) 행은 양수여야 합니다.
    final DailyPrice up = page.items.firstWhere(
      (DailyPrice price) => price.change > 0,
    );
    expect(up.direction, PriceDirection.up);
  });

  test('날짜는 최신순으로 정렬되어 있다', () {
    for (int index = 1; index < page.items.length; index++) {
      expect(
        page.items[index].date.isBefore(page.items[index - 1].date),
        isTrue,
      );
    }
  });

  test('맨뒤 링크에서 lastPage를 읽는다', () {
    expect(page.lastPage, 756);
  });

  test('맨뒤 링크가 없으면 요청한 페이지를 lastPage로 본다', () {
    // 마지막 페이지에는 `맨뒤` 링크가 없습니다.
    const String htmlWithoutNavigation = '''
      <table class="type2">
        <tr><th>날짜</th></tr>
        <tr>
          <td align="center"><span class="tah p10 gray03">2026.01.02</span></td>
          <td class="num"><span class="tah p11">1,000</span></td>
          <td class="num"><em class="bu_p bu_pn"><span class="blind">보합</span></em><span class="tah p11">0</span></td>
          <td class="num"><span class="tah p11">1,000</span></td>
          <td class="num"><span class="tah p11">1,100</span></td>
          <td class="num"><span class="tah p11">900</span></td>
          <td class="num"><span class="tah p11">12,345</span></td>
        </tr>
      </table>
    ''';

    final DailyPricePageDto parsed = SiseDayParser.parse(
      htmlWithoutNavigation,
      page: 42,
    );

    expect(parsed.lastPage, 42);
    expect(parsed.items.single.close, 1000);
  });
}
