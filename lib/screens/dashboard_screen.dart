import 'package:flutter/material.dart' hide DateRangePickerDialog;
import 'package:provider/provider.dart';
import '../models/branch.dart';
import '../providers/stock_provider.dart';
import '../services/export_service.dart';
import '../widgets/date_range_picker_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ExportService _exportService = ExportService();
  String _selectedGroupFilter = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _outletTableScrollController = ScrollController();
  bool _showGroupBreakdown = false;

  @override
  void dispose() {
    _searchController.dispose();
    _outletTableScrollController.dispose();
    super.dispose();
  }

  void _showDatePicker() async {
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final result = await showDialog<DateRangeResult>(
      context: context,
      builder: (_) => DateRangePickerDialog(
        initialFromDate: stockProvider.selectedDate,
        initialToDate: stockProvider.selectedDate,
      ),
    );
    if (result != null) {
      stockProvider.setSelectedDate(result.fromDate);
    }
  }

  String _formatDate(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final dateStr = '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
    return isToday ? 'Today ($dateStr)' : dateStr;
  }

  @override
  Widget build(BuildContext context) {
    final stockProvider = Provider.of<StockProvider>(context);

    final groupList = stockProvider.groups;
    final branchList = stockProvider.branches;
    final totalOutlets = branchList.length;
    final totalGroups = groupList.length;

    final totalAvail = branchList.fold(0, (s, b) => s + b.availableCount);
    final totalNotAvail = branchList.fold(0, (s, b) => s + b.notAvailableCount);
    final totalPending = branchList.fold(0, (s, b) => s + b.pendingCount);

    final List<_GroupStat> groupStats = groupList.map((g) {
      final gBranches = branchList.where((b) => b.groupId == g.id || (b.groupName != null && b.groupName!.contains(g.name))).toList();
      final a = gBranches.fold(0, (sum, b) => sum + b.availableCount);
      final na = gBranches.fold(0, (sum, b) => sum + b.notAvailableCount);
      final p = gBranches.fold(0, (sum, b) => sum + b.pendingCount);
      return _GroupStat(name: g.name, avail: a, notAvail: na, pending: p);
    }).toList();

    final groupFilterOptions = [
      'All Branch Groups ($totalOutlets)',
      ...groupList.map((g) => '${g.name} (${g.outletCount > 0 ? g.outletCount : branchList.where((b) => b.groupId == g.id || (b.groupName != null && b.groupName!.contains(g.name))).length})'),
    ];
    if (_selectedGroupFilter.isEmpty && groupFilterOptions.isNotEmpty) {
      _selectedGroupFilter = groupFilterOptions.first;
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      children: [
        // Top Header Greeting Banner
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E1B4B).withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Stock Overview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$totalGroups Market Groups · $totalOutlets Outlets',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: _showDatePicker,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(stockProvider.selectedDate),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Action Chips Bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _exportService.exportAndDownloadReport(
                        context,
                        endpoint: '/export/mt-msl',
                        fileName: 'Export_MT_MSL.xlsx',
                      ),
                      icon: const Icon(Icons.file_download_rounded, size: 16),
                      label: const Text('MT MSL'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _exportService.exportAndDownloadReport(
                        context,
                        endpoint: '/export/updates',
                        fileName: 'Stock_Check_Report.xlsx',
                      ),
                      icon: const Icon(Icons.description_outlined, size: 16, color: Colors.white),
                      label: const Text('Reports', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => stockProvider.initData(),
                      icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
                      label: const Text('Refresh', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section Title: Key Metrics
        const Text(
          'Key Metrics',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 12),

        // 4 Mobile Stat Cards (2x2 Grid)
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.35,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatCard(
              title: 'Daily Stock',
              value: '$totalAvail',
              subtitle: '$totalAvail Avail · $totalPending Pending',
              icon: Icons.today_rounded,
              accentColor: const Color(0xFF6366F1),
              bgColor: const Color(0xFFEEF2FF),
            ),
            _buildStatCard(
              title: 'Weekly Check',
              value: '$totalAvail / ${totalAvail + totalNotAvail + totalPending}',
              subtitle: 'Outlet activity stats',
              icon: Icons.date_range_rounded,
              accentColor: const Color(0xFF0EA5E9),
              bgColor: const Color(0xFFE0F2FE),
            ),
            _buildStatCard(
              title: 'Monthly Status',
              value: '$totalNotAvail N/A',
              subtitle: '$totalPending pending',
              icon: Icons.calendar_month_rounded,
              accentColor: const Color(0xFF10B981),
              bgColor: const Color(0xFFD1FAE5),
            ),
            _buildStatCard(
              title: 'Catalogue',
              value: '${stockProvider.products.length}',
              subtitle: '$totalOutlets outlets active',
              icon: Icons.inventory_2_rounded,
              accentColor: const Color(0xFF8B5CF6),
              bgColor: const Color(0xFFEDE9FE),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 1. Branch Groups Bar Chart & Statistics Card
        _buildBranchGroupsBarChartCard(groupStats),
        const SizedBox(height: 20),

        // 2. Daily Activity Graph Card
        _buildDailyActivityGraphCard(),
        const SizedBox(height: 20),

        // 3. Outlet Reports Main Card
        _buildOutletReportsCard(stockProvider),
        const SizedBox(height: 20),

        // 4. MT MSL Matrix Card
        _buildMtMslMatrixCard(stockProvider),
        const SizedBox(height: 20),

        // 5. Outlet Stock Matrix Card
        _buildOutletStockMatrixCard(stockProvider),
      ],
    );
  }

  double constraintsWidthFallback(double screenWidth) {
    return screenWidth < 650 ? 650 : screenWidth - 64;
  }

  Widget _buildOutletReportsCard(StockProvider stockProvider) {
    final groupList = stockProvider.groups;
    final branchList = stockProvider.branches;

    // Build options for Outlet group dropdown, e.g. "Retail Mart (3)"
    final groupOptions = groupList.map((g) {
      final count = g.outletCount > 0
          ? g.outletCount
          : branchList.where((b) => b.groupId == g.id || (b.groupName != null && b.groupName!.contains(g.name))).length;
      return '${g.name} ($count)';
    }).toList();

    if (_selectedGroupFilter.isEmpty && groupOptions.isNotEmpty) {
      _selectedGroupFilter = groupOptions.first;
    }

    final selectedGroupCleanName = _selectedGroupFilter.contains('(')
        ? _selectedGroupFilter.split('(').first.trim()
        : _selectedGroupFilter.trim();

    final selectedGroupObj = groupList.firstWhere(
      (g) => g.name.toLowerCase() == selectedGroupCleanName.toLowerCase() || selectedGroupCleanName.toLowerCase().contains(g.name.toLowerCase()),
      orElse: () => groupList.isNotEmpty
          ? groupList.first
          : BranchGroup(id: 0, name: selectedGroupCleanName.isEmpty ? 'Group' : selectedGroupCleanName, outletCount: 0, mslPerOutlet: 0),
    );

    final query = _searchController.text.trim().toLowerCase();
    final isAllGroups = selectedGroupCleanName.toLowerCase().startsWith('all');

    final selectedOutlets = branchList.where((b) {
      if (!isAllGroups) {
        bool matchesGroup = false;
        if (selectedGroupObj.id != 0 && b.groupId == selectedGroupObj.id) {
          matchesGroup = true;
        } else if (b.groupName != null && b.groupName!.isNotEmpty) {
          final gName = b.groupName!.toLowerCase();
          final clean = selectedGroupCleanName.toLowerCase();
          if (gName.contains(clean) || clean.contains(gName)) {
            matchesGroup = true;
          }
        }
        if (!matchesGroup) return false;
      }
      if (query.isNotEmpty && !b.name.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();

    final outletCount = selectedOutlets.length;
    final totalMsl = selectedOutlets.fold(0, (s, b) => s + b.mslCount);
    final totalAvail = selectedOutlets.fold(0, (s, b) => s + b.availableCount);
    final totalNotAvail = selectedOutlets.fold(0, (s, b) => s + b.notAvailableCount);
    final totalPending = selectedOutlets.fold(0, (s, b) => s + b.pendingCount);

    // Calculate group status (NOT STARTED, IN PROGRESS, COMPLETED)
    String groupStatus = 'NOT STARTED';
    Color statusBg = const Color(0xFFFFFBEB);
    Color statusTextColor = const Color(0xFFD97706);

    if (totalAvail > 0 && totalPending > 0) {
      groupStatus = 'IN PROGRESS';
      statusBg = const Color(0xFFEFF6FF);
      statusTextColor = const Color(0xFF2563EB);
    } else if (totalAvail > 0 && totalPending == 0) {
      groupStatus = 'COMPLETED';
      statusBg = const Color(0xFFF0FDF4);
      statusTextColor = const Color(0xFF16A34A);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Section Header with Title & Filters
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Outlet Reports',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$selectedGroupCleanName — $outletCount outlets',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildGroupDropdown(groupOptions, stockProvider),
                  _buildSearchBox(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Inner Group Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        selectedGroupCleanName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        groupStatus,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusTextColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$outletCount Outlets · $totalMsl MSL Items',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildSmallStatBadge('$totalAvail Available', const Color(0xFF10B981), const Color(0xFFECFDF5)),
                    _buildSmallStatBadge('$totalNotAvail N/A', const Color(0xFFEF4444), const Color(0xFFFEF2F2)),
                    _buildSmallStatBadge('$totalPending Pending', const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Table Headers & Scrollable Rows
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: constraintsWidthFallback(MediaQuery.of(context).size.width),
                child: Column(
                  children: [
                    // Header Row
                    Container(
                      color: const Color(0xFFF8FAFC),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: const Row(
                        children: [
                          Expanded(flex: 4, child: Text('OUTLET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                          Expanded(flex: 2, child: Text('MSL', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                          Expanded(flex: 2, child: Text('AVAILABLE', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                          Expanded(flex: 2, child: Text('NOT AVAIL.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                          Expanded(flex: 2, child: Text('PENDING', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                          Expanded(flex: 2, child: Text('EXPORT', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),

                    // Scrollable Table Body
                    SizedBox(
                      height: 300,
                      child: selectedOutlets.isEmpty
                          ? const Center(
                              child: Text(
                                'No outlets found for this group.',
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                              ),
                            )
                          : Scrollbar(
                              controller: _outletTableScrollController,
                              thumbVisibility: true,
                              child: ListView.separated(
                                controller: _outletTableScrollController,
                                padding: EdgeInsets.zero,
                                itemCount: selectedOutlets.length,
                                separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                itemBuilder: (ctx, index) {
                                  final b = selectedOutlets[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 4,
                                          child: Text(
                                            b.name.toUpperCase(),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '${b.mslCount}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '${b.availableCount}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '${b.notAvailableCount}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '${b.pendingCount}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Align(
                                            alignment: Alignment.center,
                                            child: SizedBox(
                                              height: 32,
                                              child: OutlinedButton(
                                                onPressed: () => _exportService.exportAndDownloadReport(
                                                  context,
                                                  endpoint: '/export/branch/${b.id}',
                                                  fileName: '${b.name}_Report.xlsx',
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                ),
                                                child: const Text(
                                                  'Export',
                                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. MT MSL Matrix Card
  Widget _buildMtMslMatrixCard(StockProvider stockProvider) {
    final groupList = stockProvider.groups;
    final productList = stockProvider.products;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MT MSL Matrix',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Group-level product assignments · ${productList.length} products',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.grid_on_rounded, color: Color(0xFF4F46E5), size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Box
          SizedBox(
            height: 38,
            child: TextField(
              onChanged: (val) => stockProvider.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'Search by name, barcode, or SL...',
                hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF64748B)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Matrix Table
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                height: 320,
                child: SingleChildScrollView(
                  child: DataTable(
                    columnSpacing: 16,
                    headingRowHeight: 40,
                    dataRowMinHeight: 44,
                    dataRowMaxHeight: 44,
                    columns: [
                      const DataColumn(label: Text('SL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                      const DataColumn(label: Text('BARCODE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                      const DataColumn(label: Text('ITEM NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                      ...groupList.map((g) => DataColumn(
                        label: Text(
                          g.name.replaceAll(RegExp(r'\s*\(\d+\)'), '').toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                        ),
                      )),
                    ],
                    rows: productList.map((p) {
                      return DataRow(
                        cells: [
                          DataCell(Text('${p.slNo}', style: const TextStyle(fontSize: 12))),
                          DataCell(Text(p.barcode, style: const TextStyle(fontSize: 11, fontFamily: 'monospace'))),
                          DataCell(Text(p.itemName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                          ...groupList.map((g) {
                            final cleanGName = g.name.replaceAll(RegExp(r'\s*\(\d+\)'), '').trim().toLowerCase();
                            final isAssigned = p.groups.any((pg) => pg.toLowerCase().contains(cleanGName) || cleanGName.contains(pg.toLowerCase()));
                            return DataCell(
                              Center(
                                child: isAssigned
                                    ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16)
                                    : const Text('-', style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
                              ),
                            );
                          }),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Legend
          const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
              SizedBox(width: 4),
              Text('In group MSL', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              SizedBox(width: 16),
              Text('-', style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 14)),
              SizedBox(width: 4),
              Text('blank = not assigned', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
  }

  // 5. Outlet Stock Matrix Card
  Widget _buildOutletStockMatrixCard(StockProvider stockProvider) {
    final branchList = stockProvider.branches;
    final productList = stockProvider.products;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Outlet Stock Matrix',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Stock check status per branch · ${branchList.length} outlets · ${productList.length} products',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.table_chart_rounded, color: Color(0xFF10B981), size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Box
          SizedBox(
            height: 38,
            child: TextField(
              onChanged: (val) => stockProvider.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'Search by name, barcode, or SL...',
                hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF64748B)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Matrix Table
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                height: 320,
                child: SingleChildScrollView(
                  child: DataTable(
                    columnSpacing: 16,
                    headingRowHeight: 40,
                    dataRowMinHeight: 44,
                    dataRowMaxHeight: 44,
                    columns: [
                      const DataColumn(label: Text('SL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                      const DataColumn(label: Text('BARCODE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                      const DataColumn(label: Text('ITEM NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                      ...branchList.map((b) => DataColumn(
                        label: Text(
                          b.name.toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      )),
                    ],
                    rows: productList.map((p) {
                      return DataRow(
                        cells: [
                          DataCell(Text('${p.slNo}', style: const TextStyle(fontSize: 12))),
                          DataCell(Text(p.barcode, style: const TextStyle(fontSize: 11, fontFamily: 'monospace'))),
                          DataCell(Text(p.itemName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                          ...branchList.map((b) {
                            final isAvail = p.isAvailable == true;
                            final isNotAvail = p.isAvailable == false;
                            return DataCell(
                              Center(
                                child: isAvail
                                    ? const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 16)
                                    : isNotAvail
                                        ? const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 16)
                                        : const Text('-', style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
                              ),
                            );
                          }),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Legend
          const Row(
            children: [
              Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 14),
              SizedBox(width: 4),
              Text('Available', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              SizedBox(width: 12),
              Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 14),
              SizedBox(width: 4),
              Text('Not Available', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              SizedBox(width: 12),
              Text('-', style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 14)),
              SizedBox(width: 4),
              Text('Pending', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupDropdown(List<String> options, StockProvider stockProvider) {
    if (options.isEmpty) return const SizedBox.shrink();
    final currentSelected = options.contains(_selectedGroupFilter) ? _selectedGroupFilter : options.first;
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentSelected,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
          onChanged: (newVal) {
            if (newVal != null) {
              setState(() {
                _selectedGroupFilter = newVal;
              });
              final cleanName = newVal.split('(').first.trim();
              final matchGroup = stockProvider.groups.firstWhere(
                (g) => g.name.toLowerCase() == cleanName.toLowerCase(),
                orElse: () => stockProvider.groups.isNotEmpty ? stockProvider.groups.first : BranchGroup(id: 0, name: cleanName),
              );
              stockProvider.setSelectedGroup(matchGroup);
            }
          },
          items: options.map((opt) {
            return DropdownMenuItem<String>(
              value: opt,
              child: Text(opt),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return SizedBox(
      height: 38,
      width: 180,
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search outlet in group...',
          hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4F46E5))),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 16, color: accentColor),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 1. Branch Groups Bar Chart & Statistics Card
  Widget _buildBranchGroupsBarChartCard(List<_GroupStat> groupStats) {
    final totalA = groupStats.fold(0, (s, g) => s + g.avail);
    final totalNA = groupStats.fold(0, (s, g) => s + g.notAvail);
    final totalP = groupStats.fold(0, (s, g) => s + g.pending);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Branch Groups Statistics',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Overview: $totalA Avail · $totalNA N/A · $totalP Pending',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF4F46E5), size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Visual Grouped Bar Chart
          SizedBox(
            height: 130,
            width: double.infinity,
            child: CustomPaint(
              painter: _BranchGroupsBarPainter(groupStats),
            ),
          ),
          const SizedBox(height: 10),

          // X-Axis Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: groupStats.map((g) {
              return Expanded(
                child: Text(
                  g.name.split(' ').first,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Legend Dots
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: Color(0xFF10B981), label: 'Available'),
              SizedBox(width: 16),
              _LegendDot(color: Color(0xFFEF4444), label: 'Not Available'),
              SizedBox(width: 16),
              _LegendDot(color: Color(0xFFF59E0B), label: 'Pending'),
            ],
          ),

          if (_showGroupBreakdown) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),
            Column(
              children: groupStats.map((g) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          g.name,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildSmallStatBadge('${g.avail}', const Color(0xFF10B981), const Color(0xFFECFDF5)),
                            const SizedBox(width: 4),
                            _buildSmallStatBadge('${g.notAvail}', const Color(0xFFEF4444), const Color(0xFFFEF2F2)),
                            const SizedBox(width: 4),
                            _buildSmallStatBadge('${g.pending}', const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _showGroupBreakdown = !_showGroupBreakdown;
                });
              },
              icon: Icon(_showGroupBreakdown ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 16, color: const Color(0xFF4F46E5)),
              label: Text(
                _showGroupBreakdown ? 'Hide group details' : 'Show group details',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStatBadge(String label, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  // 2. Daily Activity Graph Card
  Widget _buildDailyActivityGraphCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Activity Graph',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  Text('Stock check trends over time', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.show_chart_rounded, size: 14, color: Color(0xFF10B981)),
                    SizedBox(width: 4),
                    Text('PEAK: 2 PM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Custom Line & Area Graph
          SizedBox(
            height: 140,
            width: double.infinity,
            child: CustomPaint(
              painter: _DailyActivityLinePainter(),
            ),
          ),
          const SizedBox(height: 8),

          // Time Axis Labels
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('8 AM', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
              Text('10 AM', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
              Text('12 PM', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
              Text('2 PM', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
              Text('4 PM', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
              Text('6 PM', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
              Text('8 PM', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
            ],
          ),

          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: Color(0xFF10B981), label: 'Available'),
              SizedBox(width: 16),
              _LegendDot(color: Color(0xFFEF4444), label: 'Not Available'),
              SizedBox(width: 16),
              _LegendDot(color: Color(0xFFF59E0B), label: 'Pending'),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupStat {
  final String name;
  final int avail;
  final int notAvail;
  final int pending;
  const _GroupStat({required this.name, required this.avail, required this.notAvail, required this.pending});
}

class _BranchGroupsBarPainter extends CustomPainter {
  final List<_GroupStat> data;
  _BranchGroupsBarPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    const maxVal = 140.0;
    final groupWidth = size.width / data.length;
    final barWidth = (groupWidth - 10) / 3;

    final greenPaint = Paint()..color = const Color(0xFF10B981)..style = PaintingStyle.fill;
    final redPaint = Paint()..color = const Color(0xFFEF4444)..style = PaintingStyle.fill;
    final amberPaint = Paint()..color = const Color(0xFFF59E0B)..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final g = data[i];
      final startX = i * groupWidth + 4;

      final availHeight = (g.avail / maxVal) * size.height;
      final notAvailHeight = (g.notAvail / maxVal) * size.height;
      final pendingHeight = (g.pending / maxVal) * size.height;

      final r1 = RRect.fromRectAndRadius(
        Rect.fromLTWH(startX, size.height - availHeight.clamp(6.0, size.height), barWidth, availHeight.clamp(6.0, size.height)),
        const Radius.circular(3),
      );
      final r2 = RRect.fromRectAndRadius(
        Rect.fromLTWH(startX + barWidth + 2, size.height - notAvailHeight.clamp(6.0, size.height), barWidth, notAvailHeight.clamp(6.0, size.height)),
        const Radius.circular(3),
      );
      final r3 = RRect.fromRectAndRadius(
        Rect.fromLTWH(startX + (barWidth + 2) * 2, size.height - pendingHeight.clamp(6.0, size.height), barWidth, pendingHeight.clamp(6.0, size.height)),
        const Radius.circular(3),
      );

      canvas.drawRRect(r1, greenPaint);
      canvas.drawRRect(r2, redPaint);
      canvas.drawRRect(r3, amberPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _DailyActivityLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Grid horizontal background lines
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;
    for (int i = 1; i <= 3; i++) {
      final y = height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    // Line Paints
    final greenPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final redPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final amberPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Green Path (Available activity peak around 2 PM)
    final pathAvail = Path()
      ..moveTo(0, height * 0.8)
      ..cubicTo(width * 0.25, height * 0.7, width * 0.45, height * 0.15, width * 0.65, height * 0.35)
      ..quadraticBezierTo(width * 0.85, height * 0.6, width, height * 0.55);

    // Green Gradient Fill
    final pathGradient = Path.from(pathAvail)
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();

    final fillGradient = LinearGradient(
      colors: [const Color(0xFF10B981).withValues(alpha: 0.2), const Color(0xFF10B981).withValues(alpha: 0.0)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, width, height));

    final fillPaint = Paint()..shader = fillGradient..style = PaintingStyle.fill;
    canvas.drawPath(pathGradient, fillPaint);
    canvas.drawPath(pathAvail, greenPaint);

    // Red Path (Not available checks)
    final pathNotAvail = Path()
      ..moveTo(0, height * 0.9)
      ..cubicTo(width * 0.3, height * 0.95, width * 0.6, height * 0.75, width, height * 0.82);
    canvas.drawPath(pathNotAvail, redPaint);

    // Amber Path (Pending items)
    final pathPending = Path()
      ..moveTo(0, height * 0.35)
      ..cubicTo(width * 0.3, height * 0.45, width * 0.65, height * 0.25, width, height * 0.2);
    canvas.drawPath(pathPending, amberPaint);

    // Draw Data Point Circles on Green Curve
    final pointPaint = Paint()..color = const Color(0xFF10B981)..style = PaintingStyle.fill;
    final whitePointPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;

    final points = [
      Offset(0, height * 0.8),
      Offset(width * 0.5, height * 0.2),
      Offset(width * 0.65, height * 0.35),
      Offset(width, height * 0.55),
    ];

    for (final p in points) {
      canvas.drawCircle(p, 5, pointPaint);
      canvas.drawCircle(p, 2.5, whitePointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}
