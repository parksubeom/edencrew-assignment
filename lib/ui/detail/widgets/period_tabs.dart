import 'package:flutter/material.dart';

import '../../../domain/chart_period.dart';
import '../../../theme/theme.dart';

/// 기간 탭입니다. 선택된 탭에 `accentBg` 바탕과 `accentDefault` 글자색이
/// 적용됩니다.
class PeriodTabs extends StatelessWidget {
  const PeriodTabs({required this.selected, required this.onSelect, super.key});

  final ChartPeriod selected;
  final ValueChanged<ChartPeriod> onSelect;

  @override
  Widget build(BuildContext context) {
    final AppDimens dimens = context.dimens;

    return Row(
      children: <Widget>[
        for (final ChartPeriod period in ChartPeriod.values) ...<Widget>[
          Expanded(
            child: _PeriodTab(
              period: period,
              isSelected: period == selected,
              onTap: () => onSelect(period),
            ),
          ),
          if (period != ChartPeriod.values.last) SizedBox(width: dimens.space1),
        ],
      ],
    );
  }
}

class _PeriodTab extends StatelessWidget {
  const _PeriodTab({
    required this.period,
    required this.isSelected,
    required this.onTap,
  });

  final ChartPeriod period;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(dimens.radiusMd),
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? colors.accentBg : null,
          borderRadius: BorderRadius.circular(dimens.radiusMd),
        ),
        child: Text(
          period.label,
          style: TextStyle(
            color: isSelected ? colors.accentDefault : colors.textSecondary,
            fontSize: 14,
            fontWeight: isSelected
                ? AppTypography.medium
                : AppTypography.regular,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
