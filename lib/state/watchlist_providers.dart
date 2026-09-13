import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/quote.dart';
import '../domain/sort_option.dart';
import '../domain/stock_ref.dart';
import 'favorites_provider.dart';
import 'providers.dart';

/// 관심 화면의 행 하나가 필요로 하는 값 묶음입니다.
///
/// [quote]가 `null`이면 아직 시세를 받지 못한 상태이고, 화면은 그 행을
/// 스켈레톤으로 그립니다.
@immutable
class WatchlistItem {
  const WatchlistItem({required this.stock, this.quote});

  final StockRef stock;
  final Quote? quote;

  bool get hasQuote => quote != null;
}

/// 관심 목록 전체의 시세입니다.
///
/// 관심 목록이 바뀌면 이 provider가 다시 실행되면서 **한 번의 요청**으로
/// 전체를 다시 조회합니다. 종목마다 호출하지 않으므로 관심 종목이 몇 개든
/// 요청 수는 1건입니다.
///
/// 다시 조회하는 동안 Riverpod이 직전 값을 유지해 주기 때문에, 이미 시세가
/// 있던 행은 그대로 보이고 새로 추가된 행만 스켈레톤으로 나타납니다.
final FutureProvider<Map<String, Quote>> watchlistQuotesProvider =
    FutureProvider<Map<String, Quote>>((Ref ref) async {
      final List<StockRef> favorites = ref.watch(favoritesProvider);
      if (favorites.isEmpty) return const <String, Quote>{};

      return ref.watch(stockRepositoryProvider).loadQuotes(<String>[
        for (final StockRef favorite in favorites) favorite.symbol,
      ]);
    });

/// 정렬 기준입니다. 앱을 다시 켜도 마지막 선택이 남습니다.
class SortOptionNotifier extends Notifier<SortOption> {
  static const String _key = 'watchlist.sort.v1';

  @override
  SortOption build() => SortOption.fromStorage(
    ref.read(sharedPreferencesProvider).getString(_key),
  );

  void select(SortOption option) {
    if (option == state) return;
    state = option;
    ref.read(sharedPreferencesProvider).setString(_key, option.name);
  }
}

final NotifierProvider<SortOptionNotifier, SortOption> sortOptionProvider =
    NotifierProvider<SortOptionNotifier, SortOption>(SortOptionNotifier.new);

/// 화면에 그릴 최종 목록입니다. 관심 목록 · 시세 · 정렬 기준을 합칩니다.
///
/// 정렬을 위젯이 아니라 여기서 하는 이유는, 관심 화면이 "정렬된 목록을 받아
/// 그리기만" 하도록 두기 위해서입니다.
final Provider<List<WatchlistItem>> watchlistItemsProvider =
    Provider<List<WatchlistItem>>((Ref ref) {
      final List<StockRef> favorites = ref.watch(favoritesProvider);
      final Map<String, Quote> quotes =
          ref.watch(watchlistQuotesProvider).value ?? const <String, Quote>{};
      final SortOption sortOption = ref.watch(sortOptionProvider);

      final List<WatchlistItem> items = <WatchlistItem>[
        for (final StockRef favorite in favorites)
          WatchlistItem(stock: favorite, quote: quotes[favorite.symbol]),
      ];

      return sortWatchlist(items, sortOption);
    });

/// 정렬 규칙입니다.
///
/// **시세를 아직 받지 못한 행의 위치는 시안에 없어 직접 정했습니다.**
/// `현재가순` · `등락률순`은 비교할 값 자체가 없으므로 항상 목록 끝으로
/// 보냅니다. 값이 들어오면 자기 자리를 찾아가고, 그 전까지는 이미 값이 있는
/// 행들의 순서가 흔들리지 않습니다. (0으로 취급하면 하락 종목보다 위에
/// 끼어들어 순서가 두 번 바뀌어 보입니다.)
///
/// `가나다순`은 시세와 무관하므로 시세가 없어도 제자리에 놓입니다.
@visibleForTesting
List<WatchlistItem> sortWatchlist(
  List<WatchlistItem> items,
  SortOption option,
) {
  final List<WatchlistItem> sorted = <WatchlistItem>[...items];

  switch (option) {
    case SortOption.price:
      sorted.sort(
        (WatchlistItem a, WatchlistItem b) => _compareWithQuoteLast(
          a,
          b,
          (Quote quote) => quote.currentPrice.toDouble(),
        ),
      );
    case SortOption.changeRate:
      sorted.sort(
        (WatchlistItem a, WatchlistItem b) => _compareWithQuoteLast(
          a,
          b,
          (Quote quote) => quote.changeRatePercent,
        ),
      );
    case SortOption.name:
      // 한글 음절은 유니코드 코드포인트 순서가 곧 가나다 순서입니다.
      // 영문으로 시작하는 이름(SK하이닉스 등)은 코드포인트가 더 작아 앞에
      // 옵니다. 별도 로케일 정렬기를 붙이지 않고 이 동작을 그대로 씁니다.
      sorted.sort(
        (WatchlistItem a, WatchlistItem b) =>
            a.stock.name.compareTo(b.stock.name),
      );
  }

  return sorted;
}

/// 값이 큰 쪽이 위로 오고, 시세가 없는 행은 항상 아래로 갑니다.
int _compareWithQuoteLast(
  WatchlistItem a,
  WatchlistItem b,
  double Function(Quote quote) valueOf,
) {
  final Quote? left = a.quote;
  final Quote? right = b.quote;

  if (left == null && right == null) {
    return a.stock.name.compareTo(b.stock.name);
  }
  if (left == null) return 1;
  if (right == null) return -1;

  final int byValue = valueOf(right).compareTo(valueOf(left));
  // 값이 같으면 이름순으로 고정해, 다시 조회할 때마다 순서가 흔들리지
  // 않게 합니다.
  return byValue != 0 ? byValue : a.stock.name.compareTo(b.stock.name);
}
