import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'camera_service.dart';
import '../core/storage/local_database.dart';
import '../core/network/request_queue.dart';

class PurchaseApi {
  static final PurchaseApi instance = PurchaseApi._init();
  PurchaseApi._init();

  String _normalizeStatus(dynamic raw) {
    final s = (raw ?? '').toString().trim().toLowerCase();
    if (s.contains('pend')) return 'Pending Review';
    if (s.contains('approv') || s.contains('accept')) return 'Approved';
    if (s.contains('reject')) return 'Rejected';
    return 'Pending Review';
  }

  double _parseAmount(dynamic raw) {
    if (raw == null) return 0;
    if (raw is num) return raw.toDouble();
    final cleaned = raw.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  Future<List<dynamic>> getPurchases({String? date}) async {
    try {
      final results = await Future.wait([
        ApiService()
            .get('/energy/agent/apartment-purchases')
            .then<dynamic>((r) => r.data)
            .catchError((_) => null),
        ApiService()
            .get('/agent-purchases', queryParameters: {
              if (date != null && date.isNotEmpty) 'date': date,
            })
            .then<dynamic>((r) => r.data)
            .catchError((_) => null),
      ]);

      final List<Map<String, dynamic>> merged = [];
      final Map<String, int> indexBySig = {};

      // 1. Primary source: /energy/agent/apartment-purchases (apartment_cost_deployments with receipt_image)
      final acdRaw = results[0];
      final acdList = (acdRaw is Map && acdRaw['history'] is List)
          ? (acdRaw['history'] as List)
          : (acdRaw is List ? acdRaw : const []);

      for (final raw in acdList) {
        if (raw is! Map) continue;
        final item = Map<String, dynamic>.from(raw);
        final bld = (item['building_name'] ?? 'Building').toString().trim();
        final apt = (item['apartment_code'] ?? item['apartment_number'] ?? '').toString().trim();
        final sup = (item['supplier_name'] ?? item['supplier'] ?? 'Supplier').toString().trim();
        final numAmt = _parseAmount(item['amount']);
        final rawDate = (item['date'] ?? item['created_at'] ?? '').toString().split(' ').first;

        if (date != null && date.isNotEmpty && date != 'all' && rawDate.isNotEmpty && rawDate != date) {
          continue;
        }

        final notesStr = (item['notes'] ?? '').toString();
        final sig = '${bld.toLowerCase()}_${apt.toLowerCase()}_${sup.toLowerCase()}_${numAmt.round()}_$rawDate';

        final normalized = <String, dynamic>{
          'id': item['id'],
          'building_name': bld,
          'apartment_number': apt,
          'supplier': sup,
          'amount': 'CFA ${NumberFormat('#,##0').format(numAmt)}',
          'amount_num': numAmt,
          'items': notesStr.isNotEmpty ? notesStr : 'Apartment Purchase',
          'notes': notesStr,
          'purchase_date': rawDate,
          'status': _normalizeStatus(item['status']),
          'rejection_reason': item['rejection_reason'],
          'receipt_image': item['receipt_image'],
        };

        indexBySig[sig] = merged.length;
        merged.add(normalized);
      }

      // 2. Secondary source: /agent-purchases (merge if not already present, or enrich receipt_image)
      final apList = results[1] is List ? (results[1] as List) : const [];
      for (final raw in apList) {
        if (raw is! Map) continue;
        final item = Map<String, dynamic>.from(raw);
        final bld = (item['building_name'] ?? 'Galaxy').toString().trim();
        final apt = (item['apartment_number'] ?? item['apartment_code'] ?? 'A1').toString().trim();
        final sup = (item['supplier'] ?? item['supplier_name'] ?? 'Supplier').toString().trim();
        final numAmt = _parseAmount(item['amount']);
        final rawDate = (item['purchase_date'] ?? item['created_at'] ?? item['date'] ?? '')
            .toString()
            .split(' ')
            .first;

        if (date != null && date.isNotEmpty && date != 'all' && rawDate.isNotEmpty && rawDate != date) {
          continue;
        }

        final sig = '${bld.toLowerCase()}_${apt.toLowerCase()}_${sup.toLowerCase()}_${numAmt.round()}_$rawDate';
        final receipt = item['receipt_image'] ?? item['receipt_path'];

        if (indexBySig.containsKey(sig)) {
          final existingIdx = indexBySig[sig]!;
          if ((merged[existingIdx]['receipt_image'] == null ||
                  merged[existingIdx]['receipt_image'].toString().isEmpty) &&
              receipt != null &&
              receipt.toString().isNotEmpty) {
            merged[existingIdx]['receipt_image'] = receipt;
          }
          continue;
        }

        merged.add({
          'id': item['id'],
          'building_name': bld,
          'apartment_number': apt,
          'supplier': sup,
          'amount': 'CFA ${NumberFormat('#,##0').format(numAmt)}',
          'amount_num': numAmt,
          'items': (item['items'] ?? 'General Material').toString(),
          'notes': (item['notes'] ?? '').toString(),
          'purchase_date': rawDate,
          'status': _normalizeStatus(item['status']),
          'receipt_image': receipt,
        });
      }

      await LocalDatabase.instance.setCacheList('purchase_cache', merged);
      return merged;
    } catch (e) {
      final cached = await LocalDatabase.instance.getCacheList('purchase_cache');
      return cached;
    }
  }

  /// Resolves an `apartment_id` by matching building name and apartment code against `/apartments`.
  Future<int?> _resolveApartmentId(String buildingName, String apartmentCode) async {
    try {
      final res = await ApiService().get('/apartments');
      final list = res.data is List
          ? (res.data as List)
          : (res.data is Map ? (res.data['apartments'] ?? res.data['data'] ?? []) as List : const []);

      final bTarget = buildingName.trim().toLowerCase();
      final aTarget = apartmentCode.trim().toLowerCase();

      int? buildingFallbackId;
      int? codeFallbackId;

      for (final raw in list) {
        if (raw is! Map) continue;
        final id = int.tryParse((raw['id'] ?? '').toString());
        if (id == null) continue;
        final bName = (raw['building_name'] ?? '').toString().trim().toLowerCase();
        final code = (raw['code'] ?? raw['apartment_code'] ?? raw['number'] ?? '').toString().trim().toLowerCase();

        final bMatch = bTarget.isEmpty || bName == bTarget || bName.contains(bTarget) || bTarget.contains(bName);
        final aMatch = aTarget.isNotEmpty && (code == aTarget || code.replaceAll('apt ', '') == aTarget.replaceAll('apt ', ''));

        if (bMatch && aMatch) return id;
        if (bMatch && buildingFallbackId == null) buildingFallbackId = id;
        if (aMatch && codeFallbackId == null) codeFallbackId = id;
      }

      return codeFallbackId ?? buildingFallbackId;
    } catch (_) {
      return null;
    }
  }

  Future<bool> submitPurchase(Map<String, dynamic> payload) async {
    final building = (payload['building'] ?? payload['building_name'] ?? 'Galaxy').toString().trim();
    final apartment = (payload['apartment'] ?? payload['apartment_number'] ?? 'A1').toString().trim();
    final supplier = (payload['supplier'] ?? payload['supplier_name'] ?? 'Supplier').toString().trim();
    final rawAmount = (payload['amount'] ?? '0').toString();
    final numericAmount = _parseAmount(rawAmount);
    final items = (payload['items'] ?? '').toString().trim();
    final notes = (payload['notes'] ?? '').toString().trim();
    final fullNotes = [
      if (items.isNotEmpty) 'Items: $items',
      if (notes.isNotEmpty) notes,
    ].join(' • ');
    final todayStr = (payload['date'] ?? DateTime.now().toIso8601String().split('T').first).toString();

    // Extract first receipt reference from `receipts` list or `receipt_image`
    String? firstReceiptRef;
    final receiptsRaw = payload['receipts'];
    if (receiptsRaw is List && receiptsRaw.isNotEmpty) {
      firstReceiptRef = receiptsRaw.first?.toString();
    } else if (payload['receipt_image'] != null) {
      firstReceiptRef = payload['receipt_image'].toString();
    }

    final receiptBytes = await CameraService.instance.readPhotoBytes(firstReceiptRef);

    int? apartmentId = int.tryParse((payload['apartment_id'] ?? '').toString());
    apartmentId ??= await _resolveApartmentId(building, apartment);

    try {
      // 1. Primary path: submit via `/energy/agent/apartment-purchase` with MultipartFile
      //    (exact same endpoint & storage used by the website so receipt_image is stored
      //    in `uploads/receipts/agent/...` on `apartment_cost_deployments`).
      if (apartmentId != null && receiptBytes != null && receiptBytes.isNotEmpty) {
        final formData = FormData.fromMap({
          'apartment_id': apartmentId.toString(),
          'supplier_name': supplier,
          'amount': numericAmount.toStringAsFixed(0),
          'date': todayStr,
          'notes': fullNotes.isNotEmpty ? fullNotes : items,
          'receipt_image': MultipartFile.fromBytes(
            receiptBytes,
            filename: 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        });
        await ApiService().post('/energy/agent/apartment-purchase', data: formData);
        ApiService().clearCache();
        return true;
      }

      // 2. Fallback path: `/agent-purchases/submit` (also send base64 data URI if photo exists)
      final enrichedPayload = Map<String, dynamic>.from(payload);
      if (apartmentId != null) {
        enrichedPayload['apartment_id'] = apartmentId;
      }
      if (receiptBytes != null && receiptBytes.isNotEmpty) {
        final dataUri = 'data:image/jpeg;base64,${base64Encode(receiptBytes)}';
        enrichedPayload['receipt_image'] = dataUri;
        enrichedPayload['receipts'] = [dataUri];
      }
      await ApiService().post('/agent-purchases/submit', data: enrichedPayload);
      ApiService().clearCache();
      return true;
    } catch (e) {
      try {
        if (apartmentId != null && firstReceiptRef != null && firstReceiptRef.isNotEmpty) {
          await RequestQueue.instance.addRequest(
            endpoint: '/energy/agent/apartment-purchase',
            method: 'POST',
            payload: {
              'apartment_id': apartmentId.toString(),
              'supplier_name': supplier,
              'amount': numericAmount.toStringAsFixed(0),
              'date': todayStr,
              'notes': fullNotes.isNotEmpty ? fullNotes : items,
              'receipt_image': firstReceiptRef,
            },
          );
          return true;
        }
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
