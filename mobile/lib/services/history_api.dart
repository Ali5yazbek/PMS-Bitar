import 'api_service.dart';
import '../core/storage/local_database.dart';

class HistoryApi {
  static final HistoryApi instance = HistoryApi._init();
  HistoryApi._init();

  Future<Map<String, List<dynamic>>> getReadingHistory() async {
    try {
      final res = await ApiService().get('/agent/history');
      final data = (res.data as Map<String, dynamic>?) ?? {};
      final generator = (data['generator'] as List<dynamic>?) ?? [];
      final apartment = (data['apartment'] as List<dynamic>?) ?? [];
      final dailyReports = (data['daily_reports'] as List<dynamic>?) ?? [];
      final purchases = (data['purchases'] as List<dynamic>?) ?? [];

      await LocalDatabase.instance.setCacheList('history_generator', generator);
      await LocalDatabase.instance.setCacheList('history_apartment', apartment);
      await LocalDatabase.instance.setCacheList('history_daily_reports', dailyReports);
      await LocalDatabase.instance.setCacheList('history_purchases', purchases);

      return {
        'generator': generator,
        'apartment': apartment,
        'daily_reports': dailyReports,
        'purchases': purchases,
      };
    } catch (e) {
      final genCached = await LocalDatabase.instance.getCacheList('history_generator');
      final aptCached = await LocalDatabase.instance.getCacheList('history_apartment');
      final repCached = await LocalDatabase.instance.getCacheList('history_daily_reports');
      final purCached = await LocalDatabase.instance.getCacheList('history_purchases');

      return {
        'generator': genCached,
        'apartment': aptCached,
        'daily_reports': repCached,
        'purchases': purCached,
      };
    }
  }
}
