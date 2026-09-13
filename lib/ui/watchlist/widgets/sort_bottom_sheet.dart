import 'package:flutter/material.dart';

import '../../../domain/sort_option.dart';
import '../../../theme/theme.dart';

/// 정렬 바텀시트를 띄우고, 사용자가 고른 기준을 돌려줍니다.
///
/// 그냥 닫으면 `null`이 돌아오고, 그때는 기존 정렬이 유지됩니다.
Future<SortOption?> showSortBottomSheet(
  BuildContext context, {
  required SortOption selected,
}) {
  final AppColors colors = context.colors;
  final AppDimens dimens = context.dimens;

  return showModalBottomSheet<SortOption>(
    context: context,
    backgroundColor: colors.surfaceSunken,
    // 시안에서 뒤 화면이 어둡게 가려지는 부분입니다.
    barrierColor: colors.scrim,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(dimens.radiusLg),
      ),
    ),
    builder: (BuildContext context) => _SortSheet(selected: selected),
  );
}

class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.selected});

  final SortOption selected;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(
              dimens.space5,
              dimens.space5,
              dimens.space5,
              dimens.space3,
            ),
            child: Text(
              '정렬',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: AppTypography.bold,
                height: 1.4,
              ),
            ),
          ),
          for (final SortOption option in SortOption.values)
            _SortItem(
              option: option,
              isSelected: option == selected,
              onTap: () => Navigator.of(context).pop(option),
            ),
          SizedBox(height: dimens.space2),
        ],
      ),
    );
  }
}

class _SortItem extends StatelessWidget {
  const _SortItem({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final SortOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: dimens.rowMinHeight,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: dimens.space5),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  option.label,
                  style: TextStyle(
                    color: isSelected
                        ? colors.textPrimary
                        : colors.textSecondary,
                    fontSize: 15,
                    fontWeight: isSelected
                        ? AppTypography.medium
                        : AppTypography.regular,
                    height: 1.4,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_rounded,
                  size: dimens.iconMd,
                  color: colors.textPrimary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
