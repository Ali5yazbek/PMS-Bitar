import 'api_service.dart';
import '../core/storage/local_database.dart';
import '../core/network/request_queue.dart';

class GeneratorApi {
  static final GeneratorApi instance = GeneratorApi._init();
  GeneratorApi._init();

  Future<List<dynamic>> getAssignedGenerators() async {
    try {
      // Real route: GET /api/energy/generators (Real DB)
      final res = await ApiService().get('/energy/generators');
      final list = (res.data as List<dynamic>?) ?? [];
      await LocalDatabase.instance.setCacheList('generator_cache', list);
      return list;
    } catch (e) {
      final cached = await LocalDatabase.instance.getCacheList('generator_cache');
      if (cached.isNotEmpty) {
        final clean = cached.where((g) {
          final name = (g['generator_name'] ?? g['name'] ?? '').toString();
          return name != 'CAT 350kVA' || g['building_name'] != 'Galaxy';
        }).toList();
        if (clean.isNotEmpty) return clean;
      }
      return [];
    }
  }

  Future<bool> submitGeneratorReading(Map<String, dynamic> payload) async {
    final now = DateTime.now();
    if (now.hour < 7) {
      throw Exception('Generator readings locked before 07:00 AM');
    }

    try {
      await ApiService().post('/energy/agent/daily-report', data: payload);
      return true;
    } catch (e) {
      try {
        await RequestQueue.instance.addRequest(
          endpoint: '/energy/agent/daily-report',
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
