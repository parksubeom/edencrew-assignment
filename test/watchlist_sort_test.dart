import 'package:edencrew_assignment_starter/domain/quote.dart';
import 'package:edencrew_assignment_starter/domain/sort_option.dart';
import 'package:edencrew_assignment_starter/domain/stock_ref.dart';
import 'package:edencrew_assignment_starter/state/watchlist_providers.dart';
import 'package:flutter_test/flutter_test.dart';

/// 시세를 아직 받지 못한 행을 어디에 둘지는 시안에 없어 직접 정한
/// 부분이라, 규칙을 테스트로 고정해 둡니다.
void main() {
  WatchlistItem item(
    String name, {
    required String symbol,
    int? price,
    int? previousClose,
  }) {
    return WatchlistItem(
      stock: StockRef(symbol: symbol, name: name, market: '코스피'),
      quote: price == null
          ? null
          : Quote(
              symbol: symbol,
              currentPrice: price,
              previousClose: previousClose ?? price,
              open: price,
              high: price,
              low: price,
              accumulatedVolume: 0,
              listedShareCount: 0,
            ),
    );
  }

  final WatchlistItem samsung = item(
    '삼성전자',
    symbol: '005930',
    price: 179700,
    previousClose: 180100,
  );
  final WatchlistItem hynix = item(
    'SK하이닉스',
    symbol: '000660',
    price: 412500,
    previousClose: 403000,
  );
  final WatchlistItem kakao = item(
    '카카오',
    symbol: '035720',
    price: 61300,
    previousClose: 62100,
  );
  final WatchlistItem pending = item('LG에너지솔루션', symbol: '373220');

  test('현재가순은 비싼 종목이 위로 온다', () {
    final List<WatchlistItem> sorted = sortWatchlist(<WatchlistItem>[
      samsung,
      kakao,
      hynix,
    ], SortOption.price);

    expect(sorted.map((WatchlistItem it) => it.stock.name), <String>[
      'SK하이닉스',
      '삼성전자',
      '카카오',
    ]);
  });

  test('등락률순은 많이 오른 종목이 위로 온다', () {
    final List<WatchlistItem> sorted = sortWatchlist(<WatchlistItem>[
      samsung,
      kakao,
      hynix,
    ], SortOption.changeRate);

    expect(sorted.first.stock.name, 'SK하이닉스'); // +2.36%
    expect(sorted.last.stock.name, '카카오'); // -1.29%
  });

  test('시세를 못 받은 행은 현재가순에서 맨 뒤로 간다', () {
    final List<WatchlistItem> sorted = sortWatchlist(<WatchlistItem>[
      pending,
      samsung,
      hynix,
    ], SortOption.price);

    expect(sorted.last.stock.name, 'LG에너지솔루션');
    expect(sorted.last.hasQuote, isFalse);
  });

  test('시세를 못 받은 행은 등락률순에서도 맨 뒤로 간다', () {
    final List<WatchlistItem> sorted = sortWatchlist(<WatchlistItem>[
      samsung,
      pending,
      kakao,
    ], SortOption.changeRate);

    expect(sorted.last.stock.name, 'LG에너지솔루션');
  });

  test('가나다순은 시세와 무관하므로 못 받은 행도 제자리에 있다', () {
    final List<WatchlistItem> sorted = sortWatchlist(<WatchlistItem>[
      kakao,
      pending,
      samsung,
    ], SortOption.name);

    // 영문으로 시작하는 이름은 코드포인트가 더 작아 한글보다 앞에 옵니다.
    expect(sorted.map((WatchlistItem it) => it.stock.name), <String>[
      'LG에너지솔루션',
      '삼성전자',
      '카카오',
    ]);
  });

  test('정렬은 원본 목록을 건드리지 않는다', () {
    final List<WatchlistItem> original = <WatchlistItem>[kakao, samsung];
    sortWatchlist(original, SortOption.price);

    expect(original.first.stock.name, '카카오');
  });
}
