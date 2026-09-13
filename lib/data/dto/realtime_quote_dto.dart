import '../../domain/quote.dart';
import 'json_reader.dart';

/// `GET https://polling.finance.naver.com/api/realtime` 의
/// `result.areas[].datas[]` 한 건입니다.
///
/// 필드명이 두 글자로 줄어 있어서, 무엇인지 알아볼 수 있도록 이 DTO에서
/// 이름을 풀어 둡니다.
class RealtimeQuoteDto {
  const RealtimeQuoteDto({
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.previousClose,
    required this.open,
    required this.high,
    required this.low,
    required this.accumulatedVolume,
    required this.listedShareCount,
  });

  factory RealtimeQuoteDto.fromJson(Map<String, dynamic> json) =>
      RealtimeQuoteDto(
        symbol: JsonReader.stringOr(json['cd']),
        name: JsonReader.stringOr(json['nm']),
        currentPrice: JsonReader.intOr(json['nv']),
        previousClose: JsonReader.intOr(json['pcv']),
        open: JsonReader.intOr(json['ov']),
        high: JsonReader.intOr(json['hv']),
        low: JsonReader.intOr(json['lv']),
        accumulatedVolume: JsonReader.intOr(json['aq']),
        listedShareCount: JsonReader.intOr(json['countOfListedStock']),
      );

  /// `cd`
  final String symbol;

  /// `nm`. 이 endpoint는 EUC-KR로 내려오므로 디코딩을 거쳐야 읽을 수
  /// 있습니다. 화면의 종목명은 메타데이터 endpoint 값을 쓰기 때문에 실제로
  /// 화면에 나가지는 않지만, 응답을 눈으로 확인할 때 필요해 남겨 둡니다.
  final String name;

  final int currentPrice;
  final int previousClose;
  final int open;
  final int high;
  final int low;
  final int accumulatedVolume;
  final int listedShareCount;

  Quote toDomain() => Quote(
    symbol: symbol,
    currentPrice: currentPrice,
    previousClose: previousClose,
    open: open,
    high: high,
    low: low,
    accumulatedVolume: accumulatedVolume,
    listedShareCount: listedShareCount,
  );
}
