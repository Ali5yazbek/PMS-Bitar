import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../services/purchase_api.dart';
import '../services/camera_service.dart';
import '../widgets/mobile/enterprise_mobile_scaffold.dart';

final purchasesListProvider = FutureProvider.family.autoDispose<List<dynamic>, String?>((ref, dateFilter) async {
  return await PurchaseApi.instance.getPurchases(date: dateFilter);
});

final buildingsSuggestionsProvider = FutureProvider<List<dynamic>>((ref) async {
  try {
    final res = await ApiService().get('/buildings');
    final data = res.data;
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      return (data['buildings'] ?? data['data'] ?? []) as List<dynamic>;
    }
    return [];
  } catch (_) {
    return [];
  }
});

class ApartmentCostReportScreen extends ConsumerStatefulWidget {
  const ApartmentCostReportScreen({super.key});

  @override
  ConsumerState<ApartmentCostReportScreen> createState() => _ApartmentCostReportScreenState();
}

class _ApartmentCostReportScreenState extends ConsumerState<ApartmentCostReportScreen> {
  late String _selectedDateStr;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Widget _buildQuickChip(String label, VoidCallback onTap, {required bool isSelected}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : const Color(0xFF060B10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppTheme.primary : const Color(0xFF1D3347)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.blueGrey.shade300,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final purchasesAsync = ref.watch(purchasesListProvider(_selectedDateStr));
    final todayStr = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

    return EnterpriseMobileScaffold(
      title: 'Apartment Cost / Purchases',
      userRole: 'Agent',
      userName: 'Field Agent',
      currentTabIndex: 0,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Metrics Cards: Total Submitted, Pending Review, Rejected
            purchasesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
              error: (e, _) => const SizedBox.shrink(),
              data: (list) {
                final pendingCount = list.where((p) => p['status'] == 'Pending Review').length;
                final rejectedCount = list.where((p) => p['status'] == 'Rejected').length;

                return Row(
                  children: [
                    Expanded(child: _StatCard(title: 'Total Submitted', value: '${list.length}', icon: Icons.shopping_cart, color: Colors.blue)),
                    const SizedBox(width: 8),
                    Expanded(child: _StatCard(title: 'Pending Review', value: '$pendingCount', icon: Icons.hourglass_empty, color: Colors.amber)),
                    const SizedBox(width: 8),
                    Expanded(child: _StatCard(title: 'Rejected', value: '$rejectedCount', icon: Icons.cancel, color: Colors.red)),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Submit New Purchase Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                label: const Text('Submit New Purchase Submission', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                onPressed: () => _openNewPurchaseModal(context),
              ),
            ),
            const SizedBox(height: 20),

            // Date Filter Section (Defaults to Daily/Today)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1620),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1D3347)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.filter_alt_outlined, color: AppTheme.primary, size: 16),
                          const SizedBox(width: 6),
                          Text('Filter Date:', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      InkWell(
                        onTap: () async {
                          final current = DateTime.tryParse(_selectedDateStr) ?? DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: current,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            final formatted = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                            setState(() => _selectedDateStr = formatted);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF060B10),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _selectedDateStr == 'all' ? 'All History' : (_selectedDateStr == todayStr ? 'Today ($_selectedDateStr)' : _selectedDateStr),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.calendar_month, size: 14, color: AppTheme.primary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildQuickChip('Today (Daily)', () {
                        setState(() => _selectedDateStr = todayStr);
                      }, isSelected: _selectedDateStr == todayStr),
                      const SizedBox(width: 8),
                      _buildQuickChip('Yesterday', () {
                        final yest = DateTime.now().subtract(const Duration(days: 1));
                        final yestStr = '${yest.year}-${yest.month.toString().padLeft(2, '0')}-${yest.day.toString().padLeft(2, '0')}';
                        setState(() => _selectedDateStr = yestStr);
                      }, isSelected: false),
                      const SizedBox(width: 8),
                      _buildQuickChip('All History', () {
                        setState(() => _selectedDateStr = 'all');
                      }, isSelected: _selectedDateStr == 'all'),
                    ],
                  ),
                ],
              ),
            ),

            Text('Purchase Submission History', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            purchasesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('No purchase submissions recorded yet.', style: GoogleFonts.inter(color: Colors.blueGrey.shade400)),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1620),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF1D3347)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${item['building_name']} Apt ${item['apartment_number']}', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(item['amount'] ?? 'CFA 0', style: GoogleFonts.outfit(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Supplier: ${item['supplier'] ?? 'Hardware Store'} • Items: ${item['items'] ?? 'General Material'}', style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 12)),
                          const SizedBox(height: 6),
                          Text('Date: ${item['purchase_date'] ?? 'Today'}', style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 11)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openNewPurchaseModal(BuildContext context) {
    final buildingCtrl = TextEditingController(text: 'Galaxy');
    final aptCtrl = TextEditingController(text: 'A1');
    final supplierCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final itemsCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    List<String> receiptPhotos = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1620),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('New Purchase Submission', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    Consumer(
                      builder: (context, ref, _) {
                        final bAsync = ref.watch(buildingsSuggestionsProvider);
                        final list = bAsync.value ?? [];
                        final names = list.map((b) => (b['name'] ?? b['building_name'] ?? '').toString()).where((n) => n.isNotEmpty).toSet().toList();
                        if (names.isEmpty) {
                          names.addAll(['Galaxy', 'Bitar Tower', 'Palace Building']);
                        }
                        if (!names.contains(buildingCtrl.text)) {
                          buildingCtrl.text = names.first;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Building Selector with Suggestions
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Building', style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF060B10),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFF1D3347)),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: names.contains(buildingCtrl.text) ? buildingCtrl.text : names.first,
                                          dropdownColor: const Color(0xFF060B10),
                                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                          isExpanded: true,
                                          items: names.map((bName) {
                                            return DropdownMenuItem<String>(
                                              value: bName,
                                              child: Text(bName, overflow: TextOverflow.ellipsis),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setModalState(() => buildingCtrl.text = val);
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: _buildInput('Apartment', aptCtrl)),
                            ],
                          ),
                        );
                      },
                    ),
                    _buildInput('Supplier Name', supplierCtrl),
                    _buildInput('Amount (CFA)', amountCtrl, keyboardType: TextInputType.number),
                    _buildInput('Items Purchased', itemsCtrl),
                    _buildInput('Notes / Description', notesCtrl, isMultiline: true),

                    const SizedBox(height: 12),
                    Text('Upload Receipt Evidence (Camera / Gallery / PDF)', style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00A884)),
                          icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          label: const Text('Camera', style: TextStyle(color: Colors.white)),
                          onPressed: () async {
                            final base64 = await CameraService.instance.capturePhotoFromCamera();
                            if (base64 != null) {
                              setModalState(() => receiptPhotos.add(base64));
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.photo_library, size: 16, color: Color(0xFF00D4AA)),
                          label: const Text('Gallery', style: TextStyle(color: Colors.white)),
                          onPressed: () async {
                            final list = await CameraService.instance.pickMultipleFromGallery();
                            setModalState(() => receiptPhotos.addAll(list));
                          },
                        ),
                      ],
                    ),

                    if (receiptPhotos.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('✓ ${receiptPhotos.length} receipt photos attached', style: const TextStyle(color: Colors.greenAccent, fontSize: 11)),
                    ],

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (supplierCtrl.text.isEmpty || amountCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter supplier and amount')));
                            return;
                          }

                          await PurchaseApi.instance.submitPurchase({
                            'building': buildingCtrl.text,
                            'apartment': aptCtrl.text,
                            'supplier': supplierCtrl.text,
                            'amount': amountCtrl.text,
                            'items': itemsCtrl.text,
                            'notes': notesCtrl.text,
                            'receipts': receiptPhotos,
                          });

                          Navigator.pop(ctx);
                          final todayStr = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
                          setState(() => _selectedDateStr = todayStr);
                          ref.invalidate(purchasesListProvider(todayStr));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase submitted successfully ✓'), backgroundColor: Colors.green));
                        },
                        child: const Text('Submit Purchase', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInput(String label, TextEditingController ctrl, {TextInputType keyboardType = TextInputType.text, bool isMultiline = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: isMultiline ? 3 : 1,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12),
          filled: true,
          fillColor: const Color(0xFF060B10),
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1D3347))),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF0D1620), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF1D3347))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 9), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
