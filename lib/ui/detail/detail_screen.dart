import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_exception.dart';
import '../../core/formatters.dart';
import '../../domain/chart_period.dart';
import '../../domain/daily_price.dart';
import '../../domain/quote.dart';
import '../../domain/stock_ref.dart';
import '../../state/detail_providers.dart';
import '../../state/favorites_provider.dart';
import '../../theme/theme.dart';
import '../common/favorite_star_button.dart';
import '../common/inline_error_banner.dart';
import '../common/price_colors.dart';
import '../common/skeleton_box.dart';
import 'widgets/candle_chart.dart';
import 'widgets/daily_price_table.dart';
import 'widgets/period_tabs.dart';
import 'widgets/summary_cards.dart';

/// 종목 상세 화면입니다. (`03 · 종목상세`)
///
/// 목록에서 이미 알고 있는 [stock]을 받아 먼저 그리고, 메타데이터 · 시세 ·
/// 일별 시세가 도착하는 대로 채웁니다. 들어오자마자 종목명이 보이므로
/// 화면이 비었다가 채워지는 느낌이 없습니다.
class DetailScreen extends ConsumerStatefulWidget {
  const DetailScreen({required this.stock, super.key});

  final StockRef stock;

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  /// 기간 탭은 이 화면에서만 쓰는 상태라 위젯이 직접 들고 있습니다.
  /// 다른 화면과 공유할 이유가 없어 provider로 올리지 않았습니다.
  ChartPeriod _period = ChartPeriod.oneMonth;

  /// 마지막으로 받아 둔 일별 시세입니다.
  ///
  /// 기간 탭을 바꾸면 요청 키가 달라져 `AsyncValue`가 loading부터 다시
  /// 시작합니다. 그때 차트와 표가 통째로 사라졌다 나타나면 화면이 크게
  /// 깜빡이므로, 새 데이터가 올 때까지 직전 기간의 그림을 그대로 둡니다.
  List<DailyPrice>? _lastPrices;

  String get _symbol => widget.stock.symbol;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    final StockRef stock =
        ref.watch(stockMetaProvider(_symbol)).value ?? widget.stock;
    final AsyncValue<Quote> quote = ref.watch(stockQuoteProvider(_symbol));

    final DailyPriceRequest request = DailyPriceRequest(
      symbol: _symbol,
      period: _period,
    );
    final AsyncValue<List<DailyPrice>> dailyPrices = ref.watch(
      dailyPricesProvider(request),
    );

    ref.listen<AsyncValue<List<DailyPrice>>>(dailyPricesProvider(request), (
      AsyncValue<List<DailyPrice>>? previous,
      AsyncValue<List<DailyPrice>> next,
    ) {
      final List<DailyPrice>? value = next.value;
      if (value != null) setState(() => _lastPrices = value);
    });

    final List<DailyPrice> prices =
        dailyPrices.value ?? _lastPrices ?? const <DailyPrice>[];
    final bool isChartLoading = dailyPrices.isLoading && prices.isEmpty;

    return Scaffold(
      backgroundColor: colors.surfaceBase,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            _DetailHeader(stock: stock),
            if (quote.hasError)
              InlineErrorBanner(
                message: userMessageOf(quote.error!),
                onRetry: () => ref.invalidate(stockQuoteProvider(_symbol)),
              )
            else if (dailyPrices.hasError)
              InlineErrorBanner(
                message: userMessageOf(dailyPrices.error!),
                onRetry: () => ref.invalidate(dailyPricesProvider(request)),
              ),
            Expanded(
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            dimens.space4,
                            dimens.space4,
                            dimens.space4,
                            dimens.space4,
                          ),
                          child: _PriceHeadline(quote: quote),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: dimens.space4,
                          ),
                          child: PeriodTabs(
                            selected: _period,
                            onSelect: (ChartPeriod period) =>
                                setState(() => _period = period),
                          ),
                        ),
                        SizedBox(
                          // 시안에서 캔들이 차지하는 세로 폭(약 188)에 위아래
                          // 여백을 더한 값입니다.
                          height: 220,
                          child: Padding(
                            // 위 8 / 아래 24로 나눠, 캔들이 실제로 차지하는
                            // 세로 폭이 시안(약 188)과 같아지게 했습니다.
                            padding: EdgeInsets.fromLTRB(
                              dimens.space4,
                              dimens.space2,
                              dimens.space4,
                              dimens.space6,
                            ),
                            child: isChartLoading
                                ? const _ChartPlaceholder()
                                : CandleChart(prices: prices),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: dimens.space4,
                          ),
                          child: switch (quote) {
                            AsyncValue<Quote>(value: final Quote value?) =>
                              SummaryCards(quote: value),
                            _ => const _SummaryPlaceholder(),
                          },
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            dimens.space4,
                            dimens.space6,
                            dimens.space4,
                            dimens.space2,
                          ),
                          child: Text(
                            '일별 시세',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 16,
                              fontWeight: AppTypography.bold,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const DailyPriceTableHeader(),
                      ],
                    ),
                  ),
                  // 1년은 245줄이라 한 번에 만들지 않고 화면에 보이는 만큼만
                  // 만들도록 Sliver로 두었습니다.
                  SliverList.builder(
                    itemCount: prices.length,
                    itemBuilder: (BuildContext context, int index) =>
                        DailyPriceRow(price: prices[index]),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height:
                          MediaQuery.paddingOf(context).bottom + dimens.space6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 뒤로 가기 · 종목명 · `종목코드 · 시장` · 관심 등록 버튼
class _DetailHeader extends ConsumerWidget {
  const _DetailHeader({required this.stock});

  final StockRef stock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    final bool isFavorite = watchIsFavorite(ref, stock.symbol);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colors.borderSubtle,
            width: dimens.borderHairline,
          ),
        ),
      ),
      child: SizedBox(
        // 시안의 상세 헤더 높이입니다. IconButton의 기본 터치 영역(48)에
        // 맡기면 헤더가 시안보다 두꺼워져서 높이를 직접 잡았습니다.
        height: 53,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: dimens.space2),
          child: Row(
            children: <Widget>[
              Tooltip(
                message: '뒤로',
                child: InkResponse(
                  onTap: () => Navigator.of(context).maybePop(),
                  radius: dimens.space5,
                  child: Padding(
                    padding: EdgeInsets.all(dimens.space2),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 22,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      stock.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: AppTypography.bold,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stock.symbolWithMarket,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 12,
                        fontWeight: AppTypography.regular,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: dimens.space2),
              FavoriteStarButton(
                isFavorite: isFavorite,
                onTap: () => ref.read(favoritesProvider.notifier).toggle(stock),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 현재가와 전일 대비 등락입니다. 방향 아이콘(▲ / ▼)이 함께 붙습니다.
class _PriceHeadline extends StatelessWidget {
  const _PriceHeadline({required this.quote});

  final AsyncValue<Quote> quote;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    final Quote? value = quote.value;
    if (value == null) {
      return const Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          SkeletonBox(width: 150, height: 30),
          SizedBox(width: 12),
          SkeletonBox(width: 110, height: 20),
        ],
      );
    }

    final Color color = colors.textColorOf(value.direction);
    final IconData? icon = priceDirectionIcon(value.direction);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(
          Formatters.price(value.currentPrice),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 28,
            fontWeight: AppTypography.bold,
            height: 1.2,
          ),
        ),
        SizedBox(width: dimens.space2),
        Padding(
          // 큰 숫자의 밑선에 맞춰 살짝 띄웁니다.
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(
            children: <Widget>[
              if (icon != null) Icon(icon, size: 30, color: color),
              Text(
                '${Formatters.absoluteChange(value.change)} '
                '(${Formatters.signedRate(value.changeRatePercent, value.direction)})',
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: AppTypography.medium,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: context.colors.textTertiary,
        ),
      ),
    );
  }
}

class _SummaryPlaceholder extends StatelessWidget {
  const _SummaryPlaceholder();

  @override
  Widget build(BuildContext context) {
    final AppDimens dimens = context.dimens;

    Widget card() => Expanded(
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: context.colors.surfaceRaised,
          borderRadius: BorderRadius.circular(dimens.radiusMd),
        ),
      ),
    );

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            card(),
            SizedBox(width: dimens.space2),
            card(),
            SizedBox(width: dimens.space2),
            card(),
          ],
        ),
        SizedBox(height: dimens.space2),
        Row(
          children: <Widget>[
            card(),
            SizedBox(width: dimens.space2),
            card(),
          ],
        ),
      ],
    );
  }
}
