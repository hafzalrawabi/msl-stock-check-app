import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/branch.dart';
import '../models/product.dart';
import '../providers/stock_provider.dart';
import '../widgets/barcode_scanner_dialog.dart';
import '../widgets/filter_dialog.dart';

class StockCheckScreen extends StatefulWidget {
  const StockCheckScreen({super.key});

  @override
  State<StockCheckScreen> createState() => _StockCheckScreenState();
}

class _StockCheckScreenState extends State<StockCheckScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openBarcodeScanner() async {
    final provider = Provider.of<StockProvider>(context, listen: false);
    final scannedCode = await showDialog<String>(
      context: context,
      builder: (_) => const BarcodeScannerDialog(),
    );
    if (scannedCode != null && scannedCode.isNotEmpty) {
      _searchController.text = scannedCode;
      provider.setSearchQuery(scannedCode);
    }
  }

  void _openFilterDialog() {
    showDialog(
      context: context,
      builder: (_) => const FilterDialog(),
    );
  }

  void _openRemarksDialog(Product product) {
    final controller = TextEditingController(text: product.remarks ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remarks - ${product.itemName}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter remarks about stock availability...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
            onPressed: () {
              Provider.of<StockProvider>(context, listen: false).updateProductRemarks(product.id, controller.text);
              Navigator.of(ctx).pop();
            },
            child: const Text('Save Remark'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stockProvider = Provider.of<StockProvider>(context);

    return Column(
      children: [
        // Top Sticky Controls Container
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Dropdowns Row
              Row(
                children: [
                  Expanded(child: _buildGroupDropdown(stockProvider)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildBranchDropdown(stockProvider)),
                  const SizedBox(width: 8),
                  _buildFilterButton(),
                ],
              ),
              const SizedBox(height: 12),

              // Search Bar & Barcode Camera Scanner
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => stockProvider.setSearchQuery(val),
                        decoration: InputDecoration(
                          hintText: 'Search by item name or barcode...',
                          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF64748B)),
                                  onPressed: () {
                                    _searchController.clear();
                                    stockProvider.setSearchQuery('');
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _openBarcodeScanner,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: Color(0xFFF1F5F9)),

        // Product Stock List Section
        Expanded(
          child: stockProvider.isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
              : stockProvider.products.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(24),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_rounded, size: 40, color: Color(0xFF94A3B8)),
                            SizedBox(height: 8),
                            Text('No products found in branch.', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: stockProvider.products.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (ctx, index) {
                        final p = stockProvider.products[index];
                        return _buildMobileStockCard(p, stockProvider);
                      },
                    ),
        ),

        // Bottom Save / Discard Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: stockProvider.hasUnsavedChanges ? () => stockProvider.discardChanges() : null,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: stockProvider.hasUnsavedChanges ? Colors.white54 : Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Discard',
                      style: TextStyle(
                        color: stockProvider.hasUnsavedChanges ? Colors.white : Colors.white38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: stockProvider.hasUnsavedChanges
                        ? () async {
                            final messenger = ScaffoldMessenger.of(context);
                            await stockProvider.saveAllChanges();
                            messenger.showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF10B981),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                behavior: SnackBarBehavior.floating,
                                content: const Text('All stock check changes saved successfully!'),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: stockProvider.hasUnsavedChanges ? const Color(0xFF10B981) : const Color(0xFF334155),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Save All',
                          style: TextStyle(
                            color: stockProvider.hasUnsavedChanges ? Colors.white : Colors.white38,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (stockProvider.hasUnsavedChanges) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupDropdown(StockProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('GROUP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: Border.all(color: const Color(0xFFCBD5E1)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<BranchGroup>(
              isExpanded: true,
              value: provider.selectedGroup,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              items: provider.groups.map((g) {
                return DropdownMenuItem<BranchGroup>(
                  value: g,
                  child: Text(g.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) provider.setSelectedGroup(val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBranchDropdown(StockProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('OUTLET', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: Border.all(color: const Color(0xFFCBD5E1)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Branch>(
              isExpanded: true,
              value: provider.selectedBranch,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              items: provider.branches.map((b) {
                return DropdownMenuItem<Branch>(
                  value: b,
                  child: Text(b.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) provider.setSelectedBranch(val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 14.0),
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFC7D2FE)),
        ),
        child: IconButton(
          icon: const Icon(Icons.tune_rounded, color: Color(0xFF4F46E5), size: 18),
          onPressed: _openFilterDialog,
          padding: EdgeInsets.zero,
          tooltip: 'Filter Stock List',
        ),
      ),
    );
  }

  Widget _buildMobileStockCard(Product p, StockProvider provider) {
    final isAvail = p.isAvailable == true;
    final isNotAvail = p.isAvailable == false;

    final cardBorderColor = isAvail
        ? const Color(0xFF10B981)
        : isNotAvail
            ? const Color(0xFFEF4444)
            : const Color(0xFFF1F5F9);

    final cardBgColor = isAvail
        ? const Color(0xFFECFDF5)
        : isNotAvail
            ? const Color(0xFFFEF2F2)
            : Colors.white;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor, width: isAvail || isNotAvail ? 1.5 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SL & Barcode row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4)),
                child: Text('SL #${p.slNo}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
              ),
              const SizedBox(width: 8),
              Text(p.barcode, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'monospace')),
              const Spacer(),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isAvail
                      ? const Color(0xFFD1FAE5)
                      : isNotAvail
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isAvail ? 'AVAILABLE' : isNotAvail ? 'NOT AVAILABLE' : 'PENDING',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isAvail ? const Color(0xFF047857) : isNotAvail ? const Color(0xFFB91C1C) : const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Product Name
          Text(
            p.itemName,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text('ERP Stock: ${p.erpStock}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          const SizedBox(height: 12),

          // Toggle Action Buttons Row
          Row(
            children: [
              // Available Button
              Expanded(
                child: InkWell(
                  onTap: () => provider.toggleProductAvailability(p.id, true),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isAvail ? const Color(0xFF10B981) : Colors.white,
                      border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: isAvail ? Colors.white : const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Available',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isAvail ? Colors.white : const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Not Available Button
              Expanded(
                child: InkWell(
                  onTap: () => provider.toggleProductAvailability(p.id, false),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isNotAvail ? const Color(0xFFEF4444) : Colors.white,
                      border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cancel_rounded,
                          size: 16,
                          color: isNotAvail ? Colors.white : const Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'N/A',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isNotAvail ? Colors.white : const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Remark Icon Button
              InkWell(
                onTap: () => _openRemarksDialog(p),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: p.remarks != null && p.remarks!.isNotEmpty ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: p.remarks != null && p.remarks!.isNotEmpty ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0)),
                  ),
                  child: Icon(
                    Icons.edit_note_rounded,
                    color: p.remarks != null && p.remarks!.isNotEmpty ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
