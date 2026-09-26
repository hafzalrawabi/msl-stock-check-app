import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/stock_provider.dart';

class AddProductDialog extends StatefulWidget {
  const AddProductDialog({super.key});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final TextEditingController _slNoController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _itemNameController = TextEditingController();

  final Map<String, bool> _branchCheckmarks = {};

  @override
  void initState() {
    super.initState();
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    for (var g in stockProvider.groups) {
      _branchCheckmarks[g.name] = false;
    }
  }

  @override
  void dispose() {
    _slNoController.dispose();
    _barcodeController.dispose();
    _brandController.dispose();
    _itemNameController.dispose();
    super.dispose();
  }

  void _handleAddProduct() {
    if (_itemNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an Item Name')),
      );
      return;
    }

    final selectedGroups = _branchCheckmarks.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    final newProduct = Product(
      id: DateTime.now().millisecondsSinceEpoch,
      slNo: int.tryParse(_slNoController.text.trim()) ?? 1,
      barcode: _barcodeController.text.trim(),
      brand: _brandController.text.trim(),
      itemName: _itemNameController.text.trim(),
      groups: selectedGroups,
    );

    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    stockProvider.addProductLocal(newProduct);

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF16A34A),
        content: Text('Product added successfully!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Product',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 2),
            const Text(
              'Item details and branch tick marks',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('SL NO'),
                    _buildTextField(_slNoController, 'Optional'),
                    const SizedBox(height: 12),

                    _buildLabel('Barcode'),
                    _buildTextField(_barcodeController, 'Optional'),
                    const SizedBox(height: 12),

                    _buildLabel('Brand'),
                    _buildTextField(_brandController, 'Optional'),
                    const SizedBox(height: 12),

                    _buildLabel('Item Name'),
                    _buildTextField(_itemNameController, 'Product name'),
                    const SizedBox(height: 16),

                    const Text(
                      'Branches (tick marks)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView(
                        children: _branchCheckmarks.keys.map((groupName) {
                          return CheckboxListTile(
                            dense: true,
                            title: Text(groupName, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
                            value: _branchCheckmarks[groupName],
                            onChanged: (val) {
                              setState(() {
                                _branchCheckmarks[groupName] = val ?? false;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF334155))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleAddProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Add Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
        ),
      ),
    );
  }
}
