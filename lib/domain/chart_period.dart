/// 상세 화면의 기간 탭입니다.
///
/// [tradingDays]는 해당 기간의 대략적인 거래일 수, [pageCount]는 일별 시세
/// HTML을 몇 페이지까지 받아야 하는지입니다. 한 페이지에 10거래일이
/// 들어 있습니다. (NAVER_API.md의 표)
enum ChartPeriod {
  oneMonth('1개월', 20, 2),
  threeMonths('3개월', 60, 6),
  sixMonths('6개월', 120, 12),
  oneYear('1년', 245, 25);

  const ChartPeriod(this.label, this.tradingDays, this.pageCount);

  final String label;

  /// 화면에 그릴 거래일 수입니다.
  final int tradingDays;

  /// 그만큼 그리기 위해 필요한 페이지 수입니다.
  final int pageCount;
}
