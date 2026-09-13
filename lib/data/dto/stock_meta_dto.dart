import '../../domain/stock_ref.dart';
import 'json_reader.dart';

/// `GET https://stock.naver.com/api/securityFe/api/fchart/domestic/stock/{symbol}`
/// 의 응답입니다.
///
/// 화면에서 `005930 · 코스피`로 보이는 부분이 이 값입니다.
class StockMetaDto {
  const StockMetaDto({
    required this.symbolCode,
    required this.stockName,
    required this.stockExchangeNameKor,
  });

  factory StockMetaDto.fromJson(Map<String, dynamic> json) => StockMetaDto(
        symbolCode: JsonReader.stringOr(json['symbolCode']),
        stockName: JsonReader.stringOr(json['stockName']),
        stockExchangeNameKor: JsonReader.stringOr(json['stockExchangeNameKor']),
      );

  final String symbolCode;
  final String stockName;

  /// `코스피` · `코스닥`
  final String stockExchangeNameKor;

  StockRef toDomain() => StockRef(
        symbol: symbolCode,
        name: stockName,
        market: stockExchangeNameKor,
      );
}
