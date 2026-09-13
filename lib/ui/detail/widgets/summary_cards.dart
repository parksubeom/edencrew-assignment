import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../domain/quote.dart';
import '../../../theme/theme.dart';

/// 시가 · 고가 · 저가 / 거래량 · 시가총액 요약 카드입니다.
///
/// 시안대로 위 줄에 3개, 아래 줄에 2개를 놓습니다. 거래량과 시가총액은
/// 자릿수가 커서 축약해 표기합니다. (`29,113천`, `1,063조`)
class SummaryCards extends StatelessWidget {
  const SummaryCards({required this.quote, super.key});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final AppDimens dimens = context.dimens;

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _SummaryCard(
                label: '시가',
                value: Formatters.price(quote.open),
              ),
            ),
            SizedBox(width: dimens.space2),
            Expanded(
              child: _SummaryCard(
                label: '고가',
                value: Formatters.price(quote.high),
              ),
            ),
            SizedBox(width: dimens.space2),
            Expanded(
              child: _SummaryCard(
                label: '저가',
                value: Formatters.price(quote.low),
              ),
            ),
          ],
        ),
        SizedBox(height: dimens.space2),
        Row(
          children: <Widget>[
            Expanded(
              child: _SummaryCard(
                label: '거래량',
                value: Formatters.compactVolume(quote.accumulatedVolume),
              ),
            ),
            SizedBox(width: dimens.space2),
            Expanded(
              child: _SummaryCard(
                label: '시가총액',
                value: Formatters.compactMarketCap(quote.marketCap),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dimens.space3,
        vertical: dimens.space2,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(dimens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 12,
              fontWeight: AppTypography.regular,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: AppTypography.medium,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
