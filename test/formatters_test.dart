import 'package:edencrew_assignment_starter/core/formatters.dart';
import 'package:edencrew_assignment_starter/domain/price_direction.dart';
import 'package:flutter_test/flutter_test.dart';

/// 시안이 요구하는 것은 숫자 값이 아니라 **표기 형식**이므로 그 부분을
/// 확인합니다.
void main() {
  group('등락액', () {
    test('상승에는 +, 하락에는 -가 붙는다', () {
      expect(Formatters.signedChange(9500), '+9,500');
      expect(Formatters.signedChange(-400), '-400');
    });

    test('보합은 부호 없이 0이다', () {
      expect(Formatters.signedChange(0), '0');
    });
  });

  group('등락률', () {
    test('소수점 두 자리에 부호와 %가 붙는다', () {
      expect(Formatters.signedRate(2.36, PriceDirection.up), '+2.36%');
      expect(Formatters.signedRate(-0.22, PriceDirection.down), '-0.22%');
    });

    test('보합은 0.00%로 찍는다', () {
      expect(Formatters.signedRate(0, PriceDirection.flat), '0.00%');
    });

    test('반올림해서 0.00이 되어도 방향의 부호를 유지한다', () {
      // 등락률만 보고 부호를 정하면 여기서 부호가 사라져, 파란 글씨에
      // 부호가 없는 어색한 표기가 됩니다.
      expect(Formatters.signedRate(-0.001, PriceDirection.down), '-0.00%');
    });
  });

  test('관심 목록 행의 조합', () {
    expect(
      Formatters.changeWithRate(-400, -0.22, PriceDirection.down),
      '-400 (-0.22%)',
    );
    expect(Formatters.changeWithRate(0, 0, PriceDirection.flat), '0 (0.00%)');
  });

  group('축약', () {
    test('거래량은 천 단위로 줄인다', () {
      expect(Formatters.compactVolume(29113466), '29,113천');
    });

    test('1,000 미만이면 줄이지 않는다', () {
      expect(Formatters.compactVolume(940), '940');
    });

    test('시가총액은 조 단위로 줄인다', () {
      expect(Formatters.compactMarketCap(1063000000000000), '1,063조');
    });

    test('1조 미만이면 억 단위로 내려간다', () {
      // 조 단위만 쓰면 소형주가 전부 `0조`가 됩니다.
      expect(Formatters.compactMarketCap(523400000000), '5,234억');
    });
  });

  test('일별 시세의 날짜는 MM.DD 형식이다', () {
    expect(Formatters.monthDay(DateTime(2026, 3, 27)), '03.27');
  });
}
