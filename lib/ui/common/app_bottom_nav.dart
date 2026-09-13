import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// 관심 / 검색을 오가는 하단 탭 바입니다.
///
/// 선택 여부에 따라 `navActive` / `navInactive`가 아이콘과 라벨에 함께
/// 적용되고, 선택된 탭은 아이콘이 채워진 모양으로 바뀝니다.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.currentIndex,
    required this.onSelect,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        border: Border(
          top: BorderSide(
            color: colors.borderSubtle,
            width: dimens.borderHairline,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: dimens.tabBarHeight,
          child: Row(
            children: <Widget>[
              _NavItem(
                label: '관심',
                activeIcon: Icons.star_rounded,
                inactiveIcon: Icons.star_border_rounded,
                selected: currentIndex == 0,
                onTap: () => onSelect(0),
              ),
              _NavItem(
                label: '검색',
                activeIcon: Icons.search_rounded,
                inactiveIcon: Icons.search_rounded,
                selected: currentIndex == 1,
                onTap: () => onSelect(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final Color color = selected ? colors.navActive : colors.navInactive;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              selected ? activeIcon : inactiveIcon,
              size: 24,
              color: color,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: AppTypography.regular,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
