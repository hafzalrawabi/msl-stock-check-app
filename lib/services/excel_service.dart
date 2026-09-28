import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/branch.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import 'export_service.dart';

class ExcelService {
  /// Export stock report using backend API GET /api/export/stock-status, with fallback to local generation
  static Future<bool> exportStockReport({
    BuildContext? context,
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

        final validContext = (context != null && context.mounted) ? context : null;
        // ignore: use_build_context_synchronously
        await _shareOrOpenFile(file, branch?.name, context: validContext, fileName: fileName);
        return true;
      }
    } catch (e) {
      debugPrint('[ExcelService] API export failed, using local generation fallback: $e');
    }

    // Fallback to local client excel generation
    final validContext = (context != null && context.mounted) ? context : null;
    // ignore: use_build_context_synchronously
    return generateAndExportStockReport(context: validContext, branch: branch, products: products);
  }

  static Future<bool> generateAndExportStockReport({
    BuildContext? context,
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

      final validContext = (context != null && context.mounted) ? context : null;
      // ignore: use_build_context_synchronously
      await _shareOrOpenFile(file, branch?.name, context: validContext, fileName: fileName);
      return true;
    } catch (e) {
      debugPrint('[ExcelService] Error generating Excel report: $e');
      return false;
    }
  }

  static Future<void> _shareOrOpenFile(File file, String? branchName, {BuildContext? context, String? fileName}) async {
    final actualFileName = fileName ?? file.path.split('/').last;
    await ExportService.saveToDownloadsFolder(file, actualFileName);

    if (context != null && context.mounted) {
      ExportService.showExportOptionsModal(context, file, actualFileName);
      return;
    }

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

