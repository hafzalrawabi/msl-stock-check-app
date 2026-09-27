import 'package:flutter/material.dart';

class DateRangeResult {
  final DateTime fromDate;
  final DateTime toDate;
  final String label;

  DateRangeResult({
    required this.fromDate,
    required this.toDate,
    required this.label,
  });
}

class DateRangePickerDialog extends StatefulWidget {
  final DateTime initialFromDate;
  final DateTime initialToDate;

  const DateRangePickerDialog({
    super.key,
    required this.initialFromDate,
    required this.initialToDate,
  });

  @override
  State<DateRangePickerDialog> createState() => _DateRangePickerDialogState();
}

class _DateRangePickerDialogState extends State<DateRangePickerDialog> {
  late DateTime _fromDate;
  late DateTime _toDate;
  String _selectedPreset = 'Today';

  @override
  void initState() {
    super.initState();
    _fromDate = widget.initialFromDate;
    _toDate = widget.initialToDate;
  }

  void _applyPreset(String preset) {
    final now = DateTime.now();
    setState(() {
      _selectedPreset = preset;
      if (preset == 'Today') {
        _fromDate = DateTime(now.year, now.month, now.day);
        _toDate = DateTime(now.year, now.month, now.day);
      } else if (preset == 'Yesterday') {
        final yesterday = now.subtract(const Duration(days: 1));
        _fromDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
        _toDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
      } else if (preset == 'Last 7 days') {
        _fromDate = now.subtract(const Duration(days: 6));
        _toDate = DateTime(now.year, now.month, now.day);
      } else if (preset == 'Last 30 days') {
        _fromDate = now.subtract(const Duration(days: 29));
        _toDate = DateTime(now.year, now.month, now.day);
      }
    });
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked;
        _selectedPreset = 'Custom';
        if (_toDate.isBefore(_fromDate)) {
          _toDate = _fromDate;
        }
      });
    }
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: _fromDate,
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _toDate = picked;
        _selectedPreset = 'Custom';
      });
    }
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final dayStr = weekdays[dt.weekday % 7];
    final monthStr = months[dt.month - 1];
    return '$dayStr, $monthStr ${dt.day}, ${dt.year}';
  }

  String _formatDateInput(DateTime dt) {
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    return '$mm/$dd/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date range',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Select a preset or pick custom dates',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),

            // Presets Grid
            Row(
              children: [
                Expanded(child: _buildPresetButton('Today')),
                const SizedBox(width: 8),
                Expanded(child: _buildPresetButton('Yesterday')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildPresetButton('Last 7 days')),
                const SizedBox(width: 8),
                Expanded(child: _buildPresetButton('Last 30 days')),
              ],
            ),
            const SizedBox(height: 20),

            // Custom Date Inputs Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('From', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: _pickFromDate,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _formatDateInput(_fromDate),
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                                ),
                              ),
                              const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF64748B)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('To', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: _pickToDate,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _formatDateInput(_toDate),
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                                ),
                              ),
                              const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF64748B)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE2E8F0)),
            const SizedBox(height: 8),

            // Formatted Date Subtitle & Actions
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDate(_fromDate),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                  ),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF334155), fontSize: 13)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      DateRangeResult(
                        fromDate: _fromDate,
                        toDate: _toDate,
                        label: _formatDate(_fromDate),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text('Apply', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetButton(String preset) {
    final isSelected = _selectedPreset == preset;
    return OutlinedButton(
      onPressed: () => _applyPreset(preset),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
        side: BorderSide(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          width: isSelected ? 1.5 : 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: Text(
        preset,
        style: TextStyle(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF475569),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }
}
