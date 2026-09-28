import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/branch.dart';
import '../models/product.dart';
import '../providers/stock_provider.dart';
import '../services/api_service.dart';
import '../services/excel_service.dart';
import '../widgets/barcode_scanner_dialog.dart';
import '../widgets/filter_dialog.dart';
import '../widgets/group_selection_modal.dart';
import '../widgets/letter_loader.dart';
import '../widgets/outlet_selection_modal.dart';
import '../widgets/remarks_upload_dialog.dart';

class StockCheckScreen extends StatefulWidget {
  const StockCheckScreen({super.key});

  @override
  State<StockCheckScreen> createState() => _StockCheckScreenState();
}

class _StockCheckScreenState extends State<StockCheckScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode(); // Dedicated FocusNode
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose(); // Proper cleanup
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;

    // Trigger pagination when user is 200px from the bottom
    if (currentScroll >= (maxScroll - 200)) {
      final provider = Provider.of<StockProvider>(context, listen: false);
      if (!provider.isLoadingMore && provider.hasMoreProducts) {
        provider.loadMoreProducts();
      }
    }
  }

  void _unfocusSearch() {
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    }
    FocusScope.of(context).unfocus();
  }

  void _openBarcodeScanner() async {
    _unfocusSearch();
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
    _unfocusSearch();
    showDialog(
      context: context,
      builder: (_) => const FilterDialog(),
    );
  }

  void _openStockCheckDetail(Product product) async {
    _unfocusSearch();
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final branch = stockProvider.selectedBranch;
    final branchId = branch?.id ?? 0;

    Map<String, dynamic> detail = {};
    if (branchId > 0) {
      detail = await _apiService.getStockCheckDetail(product.id, branchId);
    }

    final erpStock = detail['erp_stock'] ?? detail['erpStock'] ?? product.erpStock;
    final remarksText = detail['remarks']?.toString() ?? product.remarks ?? '';
    final isAvail = detail['is_available'] == true || detail['isAvailable'] == true || product.isAvailable == true;
    final isNotAvail = detail['is_available'] == false || detail['isAvailable'] == false || product.isAvailable == false;

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.info_outline_rounded, color: Color(0xFF4F46E5), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                product.itemName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Outlet', branch?.name ?? 'Default Branch'),
                  const SizedBox(height: 6),
                  _buildDetailRow('Barcode', product.barcode),
                  const SizedBox(height: 6),
                  _buildDetailRow('SL No', '#${product.slNo}'),
                  const SizedBox(height: 6),
                  _buildDetailRow('Brand', product.brand),
                  const SizedBox(height: 6),
                  _buildDetailRow('ERP Stock', '$erpStock units'),
                  const SizedBox(height: 6),
                  _buildDetailRow(
                    'Status',
                    isAvail ? 'AVAILABLE' : isNotAvail ? 'NOT AVAILABLE' : 'PENDING',
                    color: isAvail ? const Color(0xFF10B981) : isNotAvail ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                  ),
                ],
              ),
            ),
            if (remarksText.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Remarks:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFDE68A))),
                child: Text(remarksText, style: const TextStyle(fontSize: 11, color: Color(0xFF92400E))),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
            onPressed: () {
              Navigator.of(ctx).pop();
              _openRemarksDialog(product);
            },
            child: const Text('Edit Remarks'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String val, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        Text(val, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color ?? const Color(0xFF0F172A))),
      ],
    );
  }

  Widget _buildStockPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  void _openRemarksDialog(Product product) async {
    _unfocusSearch();
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final branchId = stockProvider.selectedBranch?.id ?? 0;

    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RemarksUploadDialog(
        product: product,
        branchId: branchId,
      ),
    );

    if (updated == true) {
      stockProvider.fetchProducts(showLoader: false);
    }
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
                  const SizedBox(width: 8),
                  _buildExcelReportButton(stockProvider),
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
                        focusNode: _searchFocusNode, // Attached FocusNode
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
                              _unfocusSearch();
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
          child: RefreshIndicator(
            color: const Color(0xFF4F46E5),
            onRefresh: () async {
              _unfocusSearch();
              await stockProvider.fetchProducts();
            },
            child: stockProvider.isLoading
                ? const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 400,
                child: Center(child: LetterLoader(text: 'Loading stock catalogue...')),
              ),
            )
                : stockProvider.products.isEmpty
                ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                height: 400,
                padding: const EdgeInsets.all(24),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_rounded, size: 40, color: Color(0xFF94A3B8)),
                      SizedBox(height: 8),
                      Text('No products found in branch.', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Pull down to refresh stock list', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    ],
                  ),
                ),
              ),
            )
                : ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: stockProvider.products.length + (stockProvider.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, index) {
                if (index == stockProvider.products.length - 1 && stockProvider.isLoadingMore) {
                  return const SizedBox.shrink();
                }
                return const SizedBox(height: 12);
              },
              itemBuilder: (ctx, index) {
                if (index == stockProvider.products.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                  );
                }
                final p = stockProvider.products[index];
                return _buildMobileStockCard(p, stockProvider);
              },
            ),
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
                    onPressed: stockProvider.hasUnsavedChanges
                        ? () {
                      _unfocusSearch();
                      stockProvider.discardChanges();
                    }
                        : null,
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
                      _unfocusSearch();
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
                      backgroundColor: const Color(0xFF10B981),
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
        InkWell(
          onTap: () async {
            _unfocusSearch(); // Hide keyboard on group selection
            final selected = await showModalBottomSheet<BranchGroup>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => GroupSelectionModal(
                groups: provider.groups,
                selectedGroup: provider.selectedGroup,
              ),
            );
            if (selected != null) {
              _unfocusSearch();
              provider.setSelectedGroup(selected);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFCBD5E1)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    provider.selectedGroup?.name ?? 'Select Group',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBranchDropdown(StockProvider provider) {
    final availableBranches = provider.filteredBranches;
    Branch? currentBranch = provider.selectedBranch;
    if (availableBranches.isNotEmpty && (currentBranch == null || !availableBranches.any((b) => b.id == currentBranch!.id))) {
      currentBranch = availableBranches.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('OUTLET', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            _unfocusSearch(); // Hide keyboard on outlet tap
            final selected = await showModalBottomSheet<Branch>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => OutletSelectionModal(
                branches: availableBranches,
                selectedBranch: currentBranch,
              ),
            );
            if (selected != null) {
              _unfocusSearch(); // Ensure keyboard stays hidden after selection
              provider.setSelectedBranch(selected);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFCBD5E1)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    currentBranch?.name ?? 'Select Outlet',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
              ],
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

  Widget _buildExcelReportButton(StockProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(top: 14.0),
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: IconButton(
          icon: const Icon(Icons.table_view_rounded, color: Color(0xFF059669), size: 18),
          onPressed: () async {
            _unfocusSearch();
            final messenger = ScaffoldMessenger.of(context);
            messenger.showSnackBar(
              const SnackBar(
                backgroundColor: Color(0xFF059669),
                content: Text('Generating Excel (.xlsx) Stock Report...'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            final success = await ExcelService.exportStockReport(
              context: context,
              branch: provider.selectedBranch,
              products: provider.products,
              search: provider.searchQuery,
              brand: provider.selectedBrand == 'All Brands' ? null : provider.selectedBrand,
            );
            if (!success && mounted) {
              messenger.showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFFEF4444),
                  content: Text('Failed to generate Excel report.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          padding: EdgeInsets.zero,
          tooltip: 'Export Excel (.xlsx) Report',
        ),
      ),
    );
  }

  Widget _buildMobileStockCard(Product p, StockProvider provider) {
    final isNotAvail = p.isAvailable == false;
    final isAvail = !isNotAvail;

    final cardBorderColor = isNotAvail
        ? const Color(0xFFFCA5A5)
        : const Color(0xFF6EE7B7);

    final cardBgColor = isNotAvail
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFECFDF5);

    return InkWell(
      onTap: () => _openStockCheckDetail(p),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorderColor, width: 1.5),
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
                    color: isNotAvail
                        ? const Color(0xFFFEE2E2)
                        : const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isNotAvail ? 'NOT AVAILABLE' : 'AVAILABLE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isNotAvail ? const Color(0xFFB91C1C) : const Color(0xFF047857),
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
            const SizedBox(height: 6),
            // Stock breakdown pills (TOTAL, SHELF, BACK, UNIT)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildStockPill('TOTAL', '${p.totalStock > 0 ? p.totalStock : (p.erpStock ?? "0")}', const Color(0xFF334155)),
                _buildStockPill('SHELF', '${p.shelfStock}', const Color(0xFF64748B)),
                _buildStockPill('BACK', '${p.backStock}', const Color(0xFF64748B)),
                _buildStockPill('UNIT', p.unit, const Color(0xFF4F46E5)),
              ],
            ),
            const SizedBox(height: 10),

            // Toggle Action Buttons Row
            Row(
              children: [
                // Available Button
                Expanded(
                  child: InkWell(
                    onTap: () {
                      _unfocusSearch();
                      provider.toggleProductAvailability(p.id, true);
                    },
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
                    onTap: () {
                      _unfocusSearch();
                      provider.toggleProductAvailability(p.id, false);
                    },
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
      ),
    );
  }
}