import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

/// 검색 입력창입니다. 입력한 내용을 지우는 버튼이 오른쪽에 붙습니다.
class SearchField extends StatelessWidget {
  const SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: BorderRadius.circular(dimens.radiusLg),
        border: Border.all(
          color: colors.borderSubtle,
          width: dimens.borderHairline,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: dimens.space3),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.search_rounded,
            size: dimens.iconMd,
            color: colors.textTertiary,
          ),
          SizedBox(width: dimens.space2),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              cursorColor: colors.accentDefault,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: AppTypography.regular,
                height: 1.4,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: '종목명 또는 종목코드',
                hintStyle: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 15,
                  fontWeight: AppTypography.regular,
                  height: 1.4,
                ),
              ),
            ),
          ),
          // 지우기 버튼은 시안에 항상 떠 있습니다. 입력이 없을 때도 자리를
          // 지켜서 입력 영역의 너비가 흔들리지 않게 했습니다.
          InkResponse(
            onTap: onClear,
            radius: dimens.space5,
            child: Padding(
              padding: EdgeInsets.all(dimens.space1),
              child: Icon(
                Icons.close_rounded,
                size: dimens.iconMd,
                color: colors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
