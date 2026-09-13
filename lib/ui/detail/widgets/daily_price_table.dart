import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../domain/daily_price.dart';
import '../../../theme/theme.dart';
import '../../common/price_colors.dart';

/// 일별 시세 표의 칸 비율입니다.
///
/// 헤더와 내용 행이 같은 값을 써야 세로줄이 맞으므로 한곳에 모아 둡니다.
/// `날짜`만 왼쪽 정렬이고 나머지는 오른쪽 정렬입니다.
abstract final class DailyPriceColumns {
  static const int date = 4;
  static const int close = 6;
  static const int change = 5;
  static const int volume = 7;
}

/// `날짜 · 종가 · 등락 · 거래량` 헤더 줄입니다.
class DailyPriceTableHeader extends StatelessWidget {
  const DailyPriceTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    final TextStyle style = TextStyle(
      color: colors.textTertiary,
      fontSize: 12,
      fontWeight: AppTypography.regular,
      height: 1.4,
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: dimens.space4,
        vertical: dimens.space2,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: DailyPriceColumns.date,
            child: Text('날짜', style: style),
          ),
          Expanded(
            flex: DailyPriceColumns.close,
            child: Text('종가', style: style, textAlign: TextAlign.right),
          ),
          Expanded(
            flex: DailyPriceColumns.change,
            child: Text('등락', style: style, textAlign: TextAlign.right),
          ),
          Expanded(
            flex: DailyPriceColumns.volume,
            child: Text('거래량', style: style, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

/// 일별 시세 표의 한 줄입니다.
class DailyPriceRow extends StatelessWidget {
  const DailyPriceRow({required this.price, super.key});

  final DailyPrice price;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    final TextStyle baseStyle = TextStyle(
      color: colors.textSecondary,
      fontSize: 13,
      fontWeight: AppTypography.regular,
      height: 1.4,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colors.borderSubtle,
            width: dimens.borderHairline,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dimens.space4,
          vertical: dimens.space2,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: DailyPriceColumns.date,
              child: Text(Formatters.monthDay(price.date), style: baseStyle),
            ),
            Expanded(
              flex: DailyPriceColumns.close,
              child: Text(
                Formatters.price(price.close),
                textAlign: TextAlign.right,
                style: baseStyle.copyWith(color: colors.textPrimary),
              ),
            ),
            Expanded(
              flex: DailyPriceColumns.change,
              child: Text(
                Formatters.signedChange(price.change),
                textAlign: TextAlign.right,
                style: baseStyle.copyWith(
                  color: colors.textColorOf(price.direction),
                ),
              ),
            ),
            Expanded(
              flex: DailyPriceColumns.volume,
              child: Text(
                Formatters.price(price.volume),
                textAlign: TextAlign.right,
                style: baseStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
