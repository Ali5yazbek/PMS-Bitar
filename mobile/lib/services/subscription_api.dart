import 'package:dio/dio.dart';
import 'api_service.dart';
import '../core/storage/local_database.dart';
import '../core/network/request_queue.dart';

class SubscriptionApi {
  static final SubscriptionApi instance = SubscriptionApi._init();
  SubscriptionApi._init();

  Future<List<dynamic>> getSubscriptionTasks() async {
    try {
      // Real route: GET /api/energy/agent/subscription-tasks (DB backend)
      final res = await ApiService().get('/energy/agent/subscription-tasks');
      List<dynamic> list = [];
      if (res.data is Map<String, dynamic>) {
        final Map<String, dynamic> data = res.data;
        if (data['tasks'] != null) {
          list.addAll(data['tasks'] as List<dynamic>);
        }
        if (data['history'] != null) {
          list.addAll(data['history'] as List<dynamic>);
        }
      } else if (res.data is List) {
        list = res.data as List<dynamic>;
      }
      
      await LocalDatabase.instance.setCacheList('subscription_cache', list);
      return list;
    } catch (e) {
      print('Error fetching subscription tasks: $e');
      final cached = await LocalDatabase.instance.getCacheList('subscription_cache');
      if (cached.isNotEmpty) {
        // Filter out any stale mock items containing 'Jane Smith' or 'Cat 350'
        final cleanCached = cached.where((item) {
          final tenant = (item['tenant_name'] ?? '').toString();
          return tenant != 'Jane Smith' && tenant != 'John Doe';
        }).toList();
        if (cleanCached.isNotEmpty) return cleanCached;
      }
      return [];
    }
  }

  Future<bool> submitSubscriptionReading(Map<String, dynamic> payload) async {
    try {
      await RequestQueue.instance.addRequest(
        endpoint: '/energy/agent/subscription-reading',
        method: 'POST',
        payload: payload,
      );
      return true;
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        throw Exception(e.response?.data['error'] ?? 'Submission failed');
      }
      return false;
    }
  }
}
