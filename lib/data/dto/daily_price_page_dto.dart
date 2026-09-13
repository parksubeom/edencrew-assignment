import '../../domain/daily_price.dart';

/// 일별 시세 HTML 한 페이지를 파싱한 결과입니다.
///
/// 한 페이지에 10거래일이 들어 있고, [lastPage]는 그 종목에 존재하는 마지막
/// 페이지 번호입니다. 이 값이 있어야 없는 페이지를 요청하지 않을 수 있습니다.
class DailyPricePageDto {
  const DailyPricePageDto({
    required this.page,
    required this.items,
    required this.lastPage,
  });

  final int page;

  /// 최신 거래일이 앞에 오는 순서입니다. (HTML 표 순서 그대로)
  final List<DailyPrice> items;

  final int lastPage;
}
