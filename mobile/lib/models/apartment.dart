// ─── Apartment Model ──────────────────────────────────────────────────────────
class Apartment {
  final int id;
  final String number;
  final String? buildingName;
  final int? buildingId;
  final int floor;
  final String type;
  final String status;
  final String? currentTenantName;
  final double? rentAmount;

  const Apartment({
    required this.id,
    required this.number,
    this.buildingName,
    this.buildingId,
    required this.floor,
    required this.type,
    required this.status,
    this.currentTenantName,
    this.rentAmount,
  });

  factory Apartment.fromJson(Map<String, dynamic> j) => Apartment(
        id: _parseInt(j['id']),
        number: j['apartment_number']?.toString() ?? j['number']?.toString() ?? '',
        buildingName: j['building_name']?.toString(),
        buildingId: j['building_id'] != null ? _parseInt(j['building_id']) : null,
        floor: _parseInt(j['floor']),
        type: j['type']?.toString() ?? 'apartment',
        status: j['status']?.toString() ?? 'vacant',
        currentTenantName: j['current_tenant']?.toString() ?? j['tenant_name']?.toString(),
        rentAmount: j['rent_amount'] != null ? _parseDouble(j['rent_amount']) : null,
      );

  bool get isOccupied => status == 'occupied';

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
