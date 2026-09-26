import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stock_provider.dart';
import '../services/export_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ExportService _exportService = ExportService();
  String _selectedGroupFilter = 'Al Rawabi Group (8)';
  final TextEditingController _searchController = TextEditingController();

  final List<_GroupStat> _groupStats = const [
    _GroupStat(name: 'Saudia Group', avail: 10, notAvail: 5, pending: 130),
    _GroupStat(name: 'Ansar Gallery', avail: 5, notAvail: 2, pending: 20),
    _GroupStat(name: 'Global Max', avail: 8, notAvail: 1, pending: 30),
    _GroupStat(name: 'Mark N Save', avail: 4, notAvail: 2, pending: 15),
    _GroupStat(name: 'Monoprix', avail: 6, notAvail: 1, pending: 18),
    _GroupStat(name: 'Food Palace', avail: 2, notAvail: 1, pending: 10),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDatePicker() async {
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final picked = await showDatePicker(
      context: context,
      initialDate: stockProvider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      stockProvider.setSelectedDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stockProvider = Provider.of<StockProvider>(context);

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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stock Overview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '30 Market Groups · 52 Outlets',
                        style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
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
                      child: const Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Thu, Sep 24',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
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
              value: '0',
              subtitle: '0 Avail · 0 Pending',
              icon: Icons.today_rounded,
              accentColor: const Color(0xFF6366F1),
              bgColor: const Color(0xFFEEF2FF),
            ),
            _buildStatCard(
              title: 'Weekly Check',
              value: '12 / 52',
              subtitle: '7% items checked',
              icon: Icons.date_range_rounded,
              accentColor: const Color(0xFF0EA5E9),
              bgColor: const Color(0xFFE0F2FE),
            ),
            _buildStatCard(
              title: 'Monthly Status',
              value: '0 / 52',
              subtitle: '12,365 pending',
              icon: Icons.calendar_month_rounded,
              accentColor: const Color(0xFF10B981),
              bgColor: const Color(0xFFD1FAE5),
            ),
            _buildStatCard(
              title: 'Catalogue',
              value: '1,580',
              subtitle: '3,370 assignments',
              icon: Icons.inventory_2_rounded,
              accentColor: const Color(0xFF8B5CF6),
              bgColor: const Color(0xFFEDE9FE),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 1. Branch Groups Bar Chart & Statistics Card
        _buildBranchGroupsBarChartCard(),
        const SizedBox(height: 20),

        // 2. Daily Activity Graph Card
        _buildDailyActivityGraphCard(),
        const SizedBox(height: 20),

        // Outlets Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Outlet Reports',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                Text('Branch availability tracking', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '8 OUTLETS',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Group Filter Chips Scroll
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              'Al Rawabi Group (8)',
              'Safari Group (4)',
              'Saudia Group (6)',
              'Grand Mall (2)',
              'Retail Mart (3)',
              'Ansar Gallery (3)',
            ].map((groupName) {
              final isSelected = _selectedGroupFilter == groupName;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(groupName),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedGroupFilter = groupName);
                  },
                  selectedColor: const Color(0xFF4F46E5),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                  side: BorderSide(color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // Outlet Search Bar
        SizedBox(
          height: 44,
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search outlet name...',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Outlet Cards List
        _buildOutletCardsList(stockProvider),
      ],
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
  Widget _buildBranchGroupsBarChartCard() {
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
                    'Branch Groups Statistics',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  Text('Item breakdown per market group', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
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
            height: 140,
            width: double.infinity,
            child: CustomPaint(
              painter: _BranchGroupsBarPainter(_groupStats),
            ),
          ),
          const SizedBox(height: 12),

          // X-Axis Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _groupStats.map((g) {
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

          // Group Statistics Items Breakdown List
          Column(
            children: _groupStats.map((g) {
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
                          _buildSmallStatBadge('${g.avail} Avail', const Color(0xFF10B981), const Color(0xFFECFDF5)),
                          const SizedBox(width: 4),
                          _buildSmallStatBadge('${g.notAvail} N/A', const Color(0xFFEF4444), const Color(0xFFFEF2F2)),
                          const SizedBox(width: 4),
                          _buildSmallStatBadge('${g.pending} Pnd', const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),
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

  Widget _buildOutletCardsList(StockProvider stockProvider) {
    final query = _searchController.text.trim().toLowerCase();
    final branches = stockProvider.branches.where((b) {
      if (query.isNotEmpty && !b.name.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();

    if (branches.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('No outlets found.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: branches.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (ctx, index) {
        final b = branches[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.storefront_rounded, size: 18, color: Color(0xFF4F46E5)),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            'MSL Total: ${b.mslCount}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _exportService.exportAndDownloadReport(
                      context,
                      endpoint: '/export/branch/${b.id}',
                      fileName: '${b.name}_Report.xlsx',
                    ),
                    icon: const Icon(Icons.file_download_outlined, size: 14),
                    label: const Text('Export', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Badges Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Text('Available', style: TextStyle(fontSize: 9, color: Color(0xFF047857), fontWeight: FontWeight.bold)),
                          Text('${b.availableCount}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Text('Not Avail', style: TextStyle(fontSize: 9, color: Color(0xFFB91C1C), fontWeight: FontWeight.bold)),
                          Text('${b.notAvailableCount}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Text('Pending', style: TextStyle(fontSize: 9, color: Color(0xFFB45309), fontWeight: FontWeight.bold)),
                          Text('${b.pendingCount}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
