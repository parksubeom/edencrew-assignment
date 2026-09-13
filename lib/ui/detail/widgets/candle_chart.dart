import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/daily_price.dart';
import '../../../domain/price_direction.dart';
import '../../../theme/theme.dart';
import '../../common/price_colors.dart';

/// 캔들 차트입니다.
///
/// 차트 패키지를 먼저 찾아봤습니다. 캔들을 그리는 것 자체는 되는데, 색과
/// 여백을 시안의 토큰 값에 맞추려면 옵션을 하나하나 확인해야 할 것 같았습니다.
/// 과제 안내에도 같은 취지의 언급이 있어서, 색과 두께를 직접 통제할 수 있는
/// [CustomPainter] 쪽을 택했습니다.
///
/// 웹의 `<canvas>` 2D 컨텍스트와 쓰는 방식이 거의 같습니다.
/// `drawRect`가 `fillRect`, `drawLine`이 `moveTo`+`lineTo`+`stroke`에
/// 해당합니다.
///
/// 그리는 규칙:
/// - 데이터는 최신순으로 들어오므로 뒤집어서 **오래된 것이 왼쪽**에 오게 합니다.
/// - Y축 범위는 구간의 저가 최솟값 ~ 고가 최댓값이고, 위아래에 약간 여백을 둡니다.
/// - 캔들 색은 종가와 시가를 비교해 정합니다. (양봉 `chartLineUp` / 음봉 `chartLineDown`)
class CandleChart extends StatelessWidget {
  const CandleChart({required this.prices, super.key});

  /// 최신 거래일이 앞에 오는 순서입니다.
  final List<DailyPrice> prices;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return CustomPaint(
      size: Size.infinite,
      painter: _CandleChartPainter(
        prices: prices,
        upColor: colors.chartColorOf(PriceDirection.up),
        downColor: colors.chartColorOf(PriceDirection.down),
        flatColor: colors.chartColorOf(PriceDirection.flat),
      ),
    );
  }
}

class _CandleChartPainter extends CustomPainter {
  const _CandleChartPainter({
    required this.prices,
    required this.upColor,
    required this.downColor,
    required this.flatColor,
  });

  final List<DailyPrice> prices;
  final Color upColor;
  final Color downColor;
  final Color flatColor;

  /// 캔들이 위아래 끝에 닿지 않도록 두는 여백입니다.
  static const double _verticalPadding = 8;

  /// 캔들 하나가 차지하는 가로 칸에서 몸통이 쓰는 비율입니다.
  ///
  /// 시안의 캔들과 꼬리 비율을 눈으로 맞춰 가며 잡은 값입니다. 정해진
  /// 규격이 있는 건 아니고, 0.5는 가늘어 보이고 0.75는 칸이 붙어 보여서
  /// 그 사이로 정했습니다.
  static const double _bodyWidthRatio = 0.62;

  /// 기간이 길어지면 칸이 좁아지므로 몸통 두께에 하한을 둡니다.
  static const double _minBodyWidth = 1;

  /// 기간이 짧으면 칸이 넓어지는데, 몸통이 지나치게 두꺼워지면 캔들 차트로
  /// 보이지 않아 상한도 둡니다.
  static const double _maxBodyWidth = 12;

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.isEmpty || size.width <= 0 || size.height <= 0) return;

    // 오래된 것이 왼쪽에 오도록 뒤집습니다.
    final List<DailyPrice> ordered = prices.reversed.toList(growable: false);

    int lowest = ordered.first.low;
    int highest = ordered.first.high;
    for (final DailyPrice price in ordered) {
      lowest = math.min(lowest, price.low);
      highest = math.max(highest, price.high);
    }

    // 기간 내 가격이 한 값으로 붙어 있으면 범위가 0이 되어 나눗셈이
    // 무너집니다. 그때는 가운데 한 줄로 그립니다.
    final double range = (highest - lowest).toDouble();
    final double usableHeight = size.height - _verticalPadding * 2;

    double yOf(int value) {
      if (range == 0) return size.height / 2;
      final double ratio = (value - lowest) / range;
      return _verticalPadding + (1 - ratio) * usableHeight;
    }

    final double slotWidth = size.width / ordered.length;
    final double bodyWidth = math.max(
      _minBodyWidth,
      math.min(slotWidth * _bodyWidthRatio, _maxBodyWidth),
    );

    final Paint paint = Paint()..style = PaintingStyle.fill;
    final Paint wickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, bodyWidth * 0.16);

    for (int index = 0; index < ordered.length; index++) {
      final DailyPrice price = ordered[index];
      final Color color = switch (price.candleDirection) {
        PriceDirection.up => upColor,
        PriceDirection.down => downColor,
        PriceDirection.flat => flatColor,
      };

      final double centerX = slotWidth * (index + 0.5);

      // 꼬리 — 고가에서 저가까지
      wickPaint.color = color;
      canvas.drawLine(
        Offset(centerX, yOf(price.high)),
        Offset(centerX, yOf(price.low)),
        wickPaint,
      );

      // 몸통 — 시가와 종가 사이. 두 값이 같으면 선 하나로 보이도록
      // 최소 높이를 줍니다.
      final double openY = yOf(price.open);
      final double closeY = yOf(price.close);
      final double top = math.min(openY, closeY);
      final double bodyHeight = math.max(1, (openY - closeY).abs());

      paint.color = color;
      canvas.drawRect(
        Rect.fromLTWH(centerX - bodyWidth / 2, top, bodyWidth, bodyHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CandleChartPainter oldDelegate) =>
      !identical(oldDelegate.prices, prices) ||
      oldDelegate.upColor != upColor ||
      oldDelegate.downColor != downColor ||
      oldDelegate.flatColor != flatColor;
}
