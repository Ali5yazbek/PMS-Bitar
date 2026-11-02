import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class PdfGenerator {
  static Future<pw.Document> generateRentInvoice(Map<String, dynamic> tenant, Map<String, dynamic>? invoice) async {
    final pdf = pw.Document();

    final formatter = NumberFormat('#,###');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('Rental Invoice', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),

              pw.Text('Property Details', style: pw.TextStyle(fontSize: 18, color: PdfColors.indigo)),
              pw.SizedBox(height: 10),
              pw.Text('Building: ${tenant['building_name'] ?? 'N/A'}'),
              pw.Text('Apartment Number: ${tenant['apartment_code'] ?? 'N/A'}'),
              pw.SizedBox(height: 20),

              pw.Text('Tenant Details', style: pw.TextStyle(fontSize: 18, color: PdfColors.indigo)),
              pw.SizedBox(height: 10),
              pw.Text('Full Name: ${tenant['full_name'] ?? 'N/A'}'),
              pw.Text('Phone: ${tenant['phone'] ?? 'N/A'}'),
              pw.SizedBox(height: 20),

              if (invoice != null) ...[
                pw.Text('Invoice Details', style: pw.TextStyle(fontSize: 18, color: PdfColors.indigo)),
                pw.SizedBox(height: 10),
                pw.Text('Due Date: ${invoice['due_date'] ?? 'N/A'}'),
                pw.Text('Amount: CFA ${formatter.format(num.tryParse(invoice['amount']?.toString() ?? '0') ?? 0)}'),
                pw.Text('Status: ${invoice['status'] ?? 'N/A'}'),
              ] else ...[
                pw.Text('Contract Terms', style: pw.TextStyle(fontSize: 18, color: PdfColors.indigo)),
                pw.SizedBox(height: 10),
                pw.Text('Start Date: ${tenant['start_date'] ?? 'N/A'}'),
                pw.Text('End Date: ${tenant['end_date'] ?? 'N/A'}'),
                pw.Text('Monthly Rent: CFA ${formatter.format(num.tryParse(tenant['monthly_rent']?.toString() ?? '0') ?? 0)}'),
              ],
              
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Container(
                    width: 200,
                    decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide())),
                    padding: const pw.EdgeInsets.only(top: 8),
                    child: pw.Center(child: pw.Text('Landlord Signature')),
                  ),
                  pw.Container(
                    width: 200,
                    decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide())),
                    padding: const pw.EdgeInsets.only(top: 8),
                    child: pw.Center(child: pw.Text('Tenant Signature')),
                  ),
                ],
              ),
              pw.SizedBox(height: 40),
            ],
          );
        },
      ),
    );

    return pdf;
  }
}
