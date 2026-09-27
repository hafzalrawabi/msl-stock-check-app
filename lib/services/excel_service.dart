import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/branch.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ExcelService {
  /// Export stock report using backend API GET /api/export/stock-status, with fallback to local generation
  static Future<bool> exportStockReport({
    required Branch? branch,
    required List<Product> products,
    String? search,
    String? brand,
    bool? mslOnly,
    String? mslStatus,
  }) async {
    try {
      final apiService = ApiService();
      final reportBytes = await apiService.exportStockStatusReport(
        branchId: branch?.id,
        search: search,
        brand: brand,
        mslOnly: mslOnly,
        mslStatus: mslStatus,
      );

      if (reportBytes != null && reportBytes.isNotEmpty) {
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'MSL_Stock_Status_${branch?.name.replaceAll(RegExp(r'\s+'), '_') ?? "Report"}_$timestamp.xlsx';
        final file = File('${directory.path}/$fileName');

        await file.writeAsBytes(reportBytes);
        debugPrint('[ExcelService] Downloaded stock status report from API to: ${file.path}');

        await _shareOrOpenFile(file, branch?.name);
        return true;
      }
    } catch (e) {
      debugPrint('[ExcelService] API export failed, using local generation fallback: $e');
    }

    // Fallback to local client excel generation
    return generateAndExportStockReport(branch: branch, products: products);
  }

  static Future<bool> generateAndExportStockReport({
    required Branch? branch,
    required List<Product> products,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheetName = branch?.name.replaceAll(RegExp(r'[^\w\s]'), '') ?? 'Stock Report';
      final sheet = excel[sheetName];
      excel.setDefaultSheet(sheetName);

      // Title Header Row
      sheet.appendRow([
        TextCellValue('MSL STOCK CHECK REPORT'),
      ]);
      sheet.appendRow([
        TextCellValue('Outlet Branch: ${branch?.name ?? "All Outlets"}'),
      ]);
      sheet.appendRow([
        TextCellValue('Generated Date: ${DateTime.now().toString().split(".")[0]}'),
      ]);
      sheet.appendRow([]); // Empty spacer row

      // Table Header Row
      final headers = [
        'SL No.',
        'Barcode',
        'Item Name',
        'Brand',
        'Total Stock',
        'Shelf Stock',
        'Back Store Stock',
        'Unit',
        'Status',
        'Remarks',
      ];
      sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

      // Data Rows
      for (var p in products) {
        final isNotAvail = p.isAvailable == false;
        final statusStr = isNotAvail ? 'Not Available' : 'Available';

        sheet.appendRow([
          IntCellValue(p.slNo),
          TextCellValue(p.barcode),
          TextCellValue(p.itemName),
          TextCellValue(p.brand),
          IntCellValue(p.totalStock > 0 ? p.totalStock : (int.tryParse(p.erpStock ?? '0') ?? 0)),
          IntCellValue(p.shelfStock),
          IntCellValue(p.backStock),
          TextCellValue(p.unit),
          TextCellValue(statusStr),
          TextCellValue(p.remarks ?? ''),
        ]);
      }

      // Save file to local storage
      final bytes = excel.encode();
      if (bytes == null) return false;

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'MSL_Stock_${branch?.name.replaceAll(RegExp(r'\s+'), '_') ?? "Report"}_$timestamp.xlsx';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(bytes);
      debugPrint('[ExcelService] Saved Excel report to: ${file.path}');

      await _shareOrOpenFile(file, branch?.name);
      return true;
    } catch (e) {
      debugPrint('[ExcelService] Error generating Excel report: $e');
      return false;
    }
  }

  static Future<void> _shareOrOpenFile(File file, String? branchName) async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        try {
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(file.path)],
              subject: 'MSL Stock Status Report - ${branchName ?? "Report"}',
              text: 'Attached is the MSL Stock Status Excel report.',
            ),
          );
          return;
        } catch (e) {
          debugPrint('[ExcelService] SharePlus plugin call failed, attempting OpenFile fallback: $e');
        }
      }
      await OpenFile.open(file.path);
    } catch (e) {
      debugPrint('[ExcelService] Could not share/open file (file saved at ${file.path}): $e');
    }
  }
}
