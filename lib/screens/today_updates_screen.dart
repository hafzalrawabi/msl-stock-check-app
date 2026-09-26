import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stock_provider.dart';
import '../services/export_service.dart';

class TodayUpdatesScreen extends StatefulWidget {
  const TodayUpdatesScreen({super.key});

  @override
  State<TodayUpdatesScreen> createState() => _TodayUpdatesScreenState();
}

class _TodayUpdatesScreenState extends State<TodayUpdatesScreen> {
  final ExportService _exportService = ExportService();
  String _selectedGroup = 'All groups';
  String _selectedOutlet = 'All outlets';
  String _selectedBrand = 'All brands';

  @override
  Widget build(BuildContext context) {
    final stockProvider = Provider.of<StockProvider>(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      children: [
        // Header Banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
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
                        'Today Updates',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 2),
                      Text('Stock activity feed', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Thu, Sep 24', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _exportService.exportAndDownloadReport(
                        context,
                        endpoint: '/export/updates',
                        fileName: 'Today_Updates_Report.xlsx',
                      ),
                      icon: const Icon(Icons.file_download_rounded, size: 16),
                      label: const Text('Report XLSX', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        stockProvider.clearUpdates();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Updates cleared'),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFF87171)),
                      label: const Text('Clear', style: TextStyle(fontSize: 12, color: Color(0xFFF87171))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFF87171)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4 Mobile Stat Cards Row/Grid
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatMetric('Total Updates', '${stockProvider.updates.length}', Icons.bolt_rounded, const Color(0xFF4F46E5)),
            _buildStatMetric('Available', '${stockProvider.updates.where((u) => u.isAvailable).length}', Icons.check_circle_rounded, const Color(0xFF10B981)),
            _buildStatMetric('Not Available', '${stockProvider.updates.where((u) => !u.isAvailable).length}', Icons.cancel_rounded, const Color(0xFFEF4444)),
            _buildStatMetric('Outlets Updated', '0', Icons.storefront_rounded, const Color(0xFF0EA5E9)),
          ],
        ),
        const SizedBox(height: 18),

        // Filter chips bar
        const Text('Filter Updates', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('Group: $_selectedGroup', () {
                _showSelectDialog('Select Group', ['All groups', 'Al Rawabi Group', 'Saudia Group'], _selectedGroup, (val) => setState(() => _selectedGroup = val));
              }),
              const SizedBox(width: 8),
              _buildFilterChip('Outlet: $_selectedOutlet', () {
                _showSelectDialog('Select Outlet', ['All outlets', 'GHMK', 'RHMR', 'SAUDI MAITHER'], _selectedOutlet, (val) => setState(() => _selectedOutlet = val));
              }),
              const SizedBox(width: 8),
              _buildFilterChip('Brand: $_selectedBrand', () {
                _showSelectDialog('Select Brand', ['All brands', 'FIVE GROUP', 'Choice Food Factory'], _selectedBrand, (val) => setState(() => _selectedBrand = val));
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Updates Feed / Empty State
        stockProvider.updates.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.history_toggle_off_rounded, size: 32, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No updates recorded yet today',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Perform stock checks to see live activity here',
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: stockProvider.updates.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, index) {
                  final item = stockProvider.updates[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.isAvailable ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          color: item.isAvailable ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                              const SizedBox(height: 2),
                              Text('${item.branchName} · ${item.brand}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        Text(item.updatedAt, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildStatMetric(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }

  void _showSelectDialog(String title, List<String> options, String selected, ValueChanged<String> onSelect) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        children: options.map((opt) {
          return SimpleDialogOption(
            onPressed: () {
              onSelect(opt);
              Navigator.of(ctx).pop();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(opt, style: TextStyle(fontWeight: opt == selected ? FontWeight.bold : FontWeight.normal)),
                if (opt == selected) const Icon(Icons.check_rounded, color: Color(0xFF4F46E5), size: 18),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
