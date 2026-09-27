import 'package:flutter/material.dart';
import '../models/branch.dart';

class OutletSelectionModal extends StatefulWidget {
  final List<Branch> branches;
  final Branch? selectedBranch;

  const OutletSelectionModal({
    super.key,
    required this.branches,
    this.selectedBranch,
  });

  @override
  State<OutletSelectionModal> createState() => _OutletSelectionModalState();
}

class _OutletSelectionModalState extends State<OutletSelectionModal> {
  final TextEditingController _searchController = TextEditingController();
  List<Branch> _filteredBranches = [];

  @override
  void initState() {
    super.initState();
    _filteredBranches = widget.branches;
  }

  void _filterBranches(String q) {
    setState(() {
      if (q.isEmpty) {
        _filteredBranches = widget.branches;
      } else {
        _filteredBranches = widget.branches
            .where((b) =>
                b.name.toLowerCase().contains(q.toLowerCase()) ||
                b.code.toLowerCase().contains(q.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: Color(0xFF10B981), size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Select Outlet Branch',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: _filterBranches,
              decoration: InputDecoration(
                hintText: 'Search outlet branch...',
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Branches List
          Expanded(
            child: _filteredBranches.isEmpty
                ? const Center(
                    child: Text(
                      'No outlet branches found.',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredBranches.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (ctx, index) {
                      final branch = _filteredBranches[index];
                      final isSelected = widget.selectedBranch?.id == branch.id;

                      return InkWell(
                        onTap: () => Navigator.of(context).pop(branch),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.store_rounded,
                                    size: 18,
                                    color: isSelected ? Colors.white : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      branch.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: isSelected ? const Color(0xFF047857) : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    if (branch.mslCount > 0) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'MSL Items: ${branch.mslCount}',
                                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
