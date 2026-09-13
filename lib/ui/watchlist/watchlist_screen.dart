import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_exception.dart';
import '../../domain/quote.dart';
import '../../domain/sort_option.dart';
import '../../state/favorites_provider.dart';
import '../../state/watchlist_providers.dart';
import '../../theme/theme.dart';
import '../common/empty_state_view.dart';
import '../common/inline_error_banner.dart';
import '../detail/detail_screen.dart';
import 'widgets/sort_bottom_sheet.dart';
import 'widgets/watchlist_row.dart';

/// 관심 종목 목록 화면입니다. (`01 · 관심`)
///
/// 이 화면은 목록을 만들지 않습니다. 관심 목록 · 시세 · 정렬 기준을 합쳐
/// 정렬까지 끝낸 결과를 `watchlistItemsProvider`에서 받아 그리기만 합니다.
class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<WatchlistItem> items = ref.watch(watchlistItemsProvider);
    final AsyncValue<Map<String, Quote>> quotes = ref.watch(
      watchlistQuotesProvider,
    );
    final SortOption sortOption = ref.watch(sortOptionProvider);

    return SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          _WatchlistHeader(
            sortOption: sortOption,
            isRefreshing: quotes.isLoading,
            onRefresh: () => ref.invalidate(watchlistQuotesProvider),
            onSortTap: () async {
              final SortOption? picked = await showSortBottomSheet(
                context,
                selected: sortOption,
              );
              if (picked != null) {
                ref.read(sortOptionProvider.notifier).select(picked);
              }
            },
          ),
          if (quotes.hasError)
            InlineErrorBanner(
              message: userMessageOf(quotes.error!),
              onRetry: () => ref.invalidate(watchlistQuotesProvider),
            ),
          Expanded(
            child: items.isEmpty
                // 관심 종목이 없을 때도 헤더와 하단 탭 바는 그대로 있습니다.
                // 빈 상태는 목록 자리에만 들어갑니다.
                ? const EmptyStateView(
                    icon: Icons.star_border_rounded,
                    title: '관심 종목이 없습니다',
                    description: '검색 탭에서 종목을 찾아\n별 아이콘을 눌러 추가해 주세요.',
                  )
                : _WatchlistList(items: items),
          ),
        ],
      ),
    );
  }
}

class _WatchlistHeader extends StatelessWidget {
  const _WatchlistHeader({
    required this.sortOption,
    required this.isRefreshing,
    required this.onRefresh,
    required this.onSortTap,
  });

  final SortOption sortOption;
  final bool isRefreshing;
  final VoidCallback onRefresh;
  final VoidCallback onSortTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return SizedBox(
      // 시안의 헤더 높이입니다. IconButton의 기본 터치 영역(48)에 맡기면
      // 헤더가 시안보다 두꺼워져서 높이를 직접 잡았습니다.
      height: 52,
      child: Padding(
        padding: EdgeInsets.only(left: dimens.space4, right: dimens.space2),
        child: Row(
          children: <Widget>[
            Text(
              '관심',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: AppTypography.bold,
                height: 1.4,
              ),
            ),
            const Spacer(),
            _SortChip(label: sortOption.label, onTap: onSortTap),
            SizedBox(width: dimens.space1),
            Tooltip(
              message: '시세 새로고침',
              child: InkResponse(
                // 조회 중에 또 누르면 요청이 겹치므로 잠급니다.
                onTap: isRefreshing ? null : onRefresh,
                radius: dimens.space5,
                child: Padding(
                  padding: EdgeInsets.all(dimens.space2),
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 22,
                    color: isRefreshing
                        ? colors.textDisabled
                        : colors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 현재 정렬 기준을 보여주고, 누르면 바텀시트를 여는 칩입니다.
class _SortChip extends StatelessWidget {
  const _SortChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(dimens.radiusMd),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dimens.space2,
          vertical: dimens.space1,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                fontWeight: AppTypography.medium,
                height: 1.4,
              ),
            ),
            SizedBox(width: dimens.space1),
            Icon(
              Icons.arrow_downward_rounded,
              size: dimens.iconSm,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _WatchlistList extends ConsumerWidget {
  const _WatchlistList({required this.items});

  final List<WatchlistItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(watchlistQuotesProvider);
        // 인디케이터가 조회가 끝날 때까지 돌도록 결과를 기다립니다.
        await ref.read(watchlistQuotesProvider.future);
      },
      color: context.colors.accentDefault,
      backgroundColor: context.colors.surfaceRaised,
      child: ListView.builder(
        // 항목이 화면을 다 채우지 않아도 아래로 당겨 새로고침할 수 있게 합니다.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) {
          final WatchlistItem item = items[index];
          return Dismissible(
            key: ValueKey<String>(item.stock.id),
            direction: DismissDirection.endToStart,
            background: const _DeleteBackground(),
            onDismissed: (_) =>
                ref.read(favoritesProvider.notifier).toggle(item.stock),
            child: WatchlistRow(
              item: item,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => DetailScreen(stock: item.stock),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 스와이프로 관심 종목을 뺄 때 뒤에 드러나는 면입니다.
///
/// 빨강은 이 앱에서 `상승`을 뜻하므로 삭제에 쓰지 않았습니다. 대신
/// `feedbackWarning`으로 "되돌릴 동작"임을 나타냅니다.
class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return ColoredBox(
      color: colors.surfaceSunken,
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: dimens.space5),
          child: Icon(
            Icons.delete_outline_rounded,
            size: 22,
            color: colors.feedbackWarning,
          ),
        ),
      ),
    );
  }
}
