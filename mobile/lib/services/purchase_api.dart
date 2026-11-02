import 'api_service.dart';
import '../core/storage/local_database.dart';
import '../core/network/request_queue.dart';

class PurchaseApi {
  static final PurchaseApi instance = PurchaseApi._init();
  PurchaseApi._init();

  Future<List<dynamic>> getPurchases({String? date}) async {
    try {
      final query = (date != null && date.isNotEmpty) ? '?date=$date' : '';
      final res = await ApiService().get('/agent-purchases$query');
      final list = (res.data as List<dynamic>?) ?? [];
      await LocalDatabase.instance.setCacheList('purchase_cache', list);
      return list;
    } catch (e) {
      final cached = await LocalDatabase.instance.getCacheList('purchase_cache');
      return cached;
    }
  }

  Future<bool> submitPurchase(Map<String, dynamic> payload) async {
    try {
      await ApiService().post('/agent-purchases/submit', data: payload);
      return true;
    } catch (e) {
      try {
        await RequestQueue.instance.addRequest(
          endpoint: '/agent-purchases/submit',
          method: 'POST',
          payload: payload,
        );
        return true;
      } catch (_) {
        return false;
      }
    }
  }
}
