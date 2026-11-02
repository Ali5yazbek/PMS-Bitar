import 'api_service.dart';
import 'package:dio/dio.dart';
import '../core/storage/local_database.dart';

class AgentApi {
  static final AgentApi instance = AgentApi._init();
  AgentApi._init();

  Future<Map<String, dynamic>> getDashboardMetrics() async {
    try {
      // Real route: GET /api/energy/agent/dashboard-stats
      final res = await ApiService().get('/energy/agent/dashboard-stats');
      final data = (res.data as Map<String, dynamic>?) ?? {};
      await LocalDatabase.instance.cacheData('agent_dashboard_metrics', data);
      return data;
    } catch (e) {
      // Try offline cache before failing — never return fake data
      final cached = await LocalDatabase.instance.getCachedData('agent_dashboard_metrics');
      if (cached != null) return cached;
      throw Exception('Failed to load dashboard metrics from live server: $e');
    }
  }

  Stream<Map<String, dynamic>> getDashboardMetricsStream() async* {
    // 1. Yield cache immediately for instant UI (cache-first)
    final cached = await LocalDatabase.instance.getCachedData('agent_dashboard_metrics');
    if (cached != null) {
      yield cached;
    }

    // 2. Fetch fresh data from live API, cache it, yield it
    try {
      // Real route: GET /api/energy/agent/dashboard-stats
      final res = await ApiService().get('/energy/agent/dashboard-stats');
      final data = (res.data as Map<String, dynamic>?) ?? {};
      await LocalDatabase.instance.cacheData('agent_dashboard_metrics', data);
      yield data;
    } catch (e) {
      // Only rethrow when no cache was yielded — avoids crashing stream with valid cached UI
      if (cached == null) {
        throw Exception('Failed to load dashboard metrics from live server: $e');
      }
    }
  }

  Future<Map<String, dynamic>> getRentTasks() async {
    try {
      final res = await ApiService().get('/agent/rent/tasks');
      final data = (res.data as Map<String, dynamic>?) ?? {};
      await LocalDatabase.instance.cacheData('agent_rent_tasks', data);
      return data;
    } catch (e) {
      final cached = await LocalDatabase.instance.getCachedData('agent_rent_tasks');
      if (cached != null) return cached;
      throw Exception('Failed to load rent tasks: $e');
    }
  }

  Future<Map<String, dynamic>> collectRent(Map<String, dynamic> payload) async {
    try {
      if (payload['type'] == 'Electricity Subscription') {
        final res = await ApiService().post('/energy/agent/subscription-invoices/pay', data: {
          'invoice_id': payload['invoice_id'],
          'amount_collected': payload['amount'],
          'status': 'collected',
          'notes': payload['notes'],
        });
        final data = res.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return {'status': 'success', 'message': data['message'] ?? 'Payment collected'};
        }
        throw Exception(data['error'] ?? data['message'] ?? 'Failed to collect payment');
      }
      final res = await ApiService().post('/agent/rent/collect', data: payload);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data.containsKey('message')) {
          throw Exception(data['message']);
        }
      }
      throw Exception('Server error: ${e.response?.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getRentHistory() async {
    try {
      final res = await ApiService().get('/agent/rent/history');
      final data = (res.data as Map<String, dynamic>?) ?? {};
      await LocalDatabase.instance.cacheData('agent_rent_history', data);
      return data;
    } catch (e) {
      final cached = await LocalDatabase.instance.getCachedData('agent_rent_history');
      if (cached != null) return cached;
      throw Exception('Failed to load rent history: $e');
    }
  }

  Stream<List<dynamic>> getSmartTasksStream() async* {
    final cached = await LocalDatabase.instance.getCachedData('agent_smart_tasks');
    if (cached != null) {
      yield cached['tasks'] ?? [];
    }
    try {
      final res = await ApiService().get('/agent/smart-tasks');
      final data = (res.data as Map<String, dynamic>?) ?? {};
      await LocalDatabase.instance.cacheData('agent_smart_tasks', data);
      yield data['tasks'] ?? [];
    } catch (e) {
      if (cached == null) {
        throw Exception('Failed to load smart tasks: $e');
      }
    }
  }

  Future<Map<String, dynamic>> quickEditReading(Map<String, dynamic> payload) async {
    final res = await ApiService().post('/agent/reading/quick-edit', data: payload);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> requestCorrection(Map<String, dynamic> payload) async {
    final res = await ApiService().post('/agent/reading/correction', data: payload);
    return res.data as Map<String, dynamic>;
  }

  /// Look up an unpaid invoice by invoice_number or QR code payload.
  /// Returns full invoice details including tenant name, amount, apartment.
  Future<Map<String, dynamic>?> lookupInvoice(String code) async {
    try {
      final res = await ApiService().get('/agent/rent/invoice-lookup', queryParameters: {'code': code});
      final data = res.data as Map<String, dynamic>?;
      if (data != null && data['status'] == 'success') {
        return data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get all unpaid rent invoices for a specific apartment (used in wizard step 4.5).
  Future<List<dynamic>> getApartmentUnpaidInvoices(int apartmentId) async {
    try {
      final res = await ApiService().get('/agent/rent/apartment-invoices', queryParameters: {'apartment_id': apartmentId.toString()});
      final data = res.data as Map<String, dynamic>?;
      if (data != null && data['status'] == 'success') {
        return (data['data'] as List<dynamic>?) ?? [];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Validate a QR code or manual code against a specific invoice_id.
  /// Returns {valid: true} if the code matches, {valid: false, message: '...'} otherwise.
  Future<Map<String, dynamic>> validateQrCode({required int invoiceId, required String qrCode}) async {
    try {
      final res = await ApiService().post('/agent/rent/validate-qr', data: {
        'invoice_id': invoiceId,
        'qr_code': qrCode,
      });
      return res.data as Map<String, dynamic>? ?? {'valid': false, 'message': 'Unknown error'};
    } catch (e) {
      return {'valid': false, 'message': 'Validation failed: $e'};
    }
  }
}
