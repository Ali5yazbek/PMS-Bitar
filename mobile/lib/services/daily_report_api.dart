import 'api_service.dart';
import '../core/storage/local_database.dart';
import '../core/network/request_queue.dart';

class DailyReportApi {
  static final DailyReportApi instance = DailyReportApi._init();
  DailyReportApi._init();

  Future<bool> submitDailyReport(Map<String, dynamic> payload) async {
    try {
      await RequestQueue.instance.addRequest(
        endpoint: '/agent/daily-report/submit',
        method: 'POST',
        payload: payload,
      );
      await LocalDatabase.instance.cacheData('latest_daily_report', payload);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getLatestDailyReport() async {
    try {
      final res = await ApiService().get('/agent/daily-report/latest');
      final data = res.data as Map<String, dynamic>?;
      if (data != null) {
        await LocalDatabase.instance.cacheData('latest_daily_report', data);
      }
      return data;
    } catch (e) {
      return await LocalDatabase.instance.getCachedData('latest_daily_report');
    }
  }
}
