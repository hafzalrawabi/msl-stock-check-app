import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class RemarksUploadDialog extends StatefulWidget {
  final Product product;
  final int branchId;

  const RemarksUploadDialog({
    super.key,
    required this.product,
    required this.branchId,
  });

  @override
  State<RemarksUploadDialog> createState() => _RemarksUploadDialogState();
}

class _RemarksUploadDialogState extends State<RemarksUploadDialog> {
  final ApiService _apiService = ApiService();
  late final TextEditingController _remarksController;
  final ImagePicker _picker = ImagePicker();

  final List<XFile> _newImages = [];
  List<String> _existingImageUrls = [];
  bool _isLoadingImages = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _remarksController = TextEditingController(text: widget.product.remarks ?? '');
    _fetchExistingImages();
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _fetchExistingImages() async {
    if (widget.branchId <= 0) return;
    setState(() => _isLoadingImages = true);

    try {
      final detail = await _apiService.getStockCheckDetail(widget.product.id, widget.branchId);
      if (detail.isNotEmpty && detail['remarks'] != null && _remarksController.text.isEmpty) {
        _remarksController.text = detail['remarks'].toString();
      }

      final images = await _apiService.getStockCheckImages(widget.product.id, widget.branchId);
      if (mounted) {
        setState(() {
          _existingImageUrls = images;
          _isLoadingImages = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingImages = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (picked != null) {
        setState(() {
          _newImages.add(picked);
        });
      }
    } catch (e) {
      debugPrint('[RemarksUploadDialog] Error picking image: $e');
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  Future<void> _saveRemarksAndUpload() async {
    setState(() => _isSaving = true);
    final remarksText = _remarksController.text.trim();

    // 1. Submit stock check update with remarks
    await _apiService.updateStockCheck(
      productId: widget.product.id,
      branchId: widget.branchId,
      isAvailable: widget.product.isAvailable ?? true,
      remarks: remarksText,
    );
    widget.product.remarks = remarksText;

    // 2. Upload new image files
    for (final xFile in _newImages) {
      await _apiService.uploadStockCheckImage(
        widget.product.id,
        widget.branchId,
        xFile.path,
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dialog Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_note_rounded, color: Color(0xFF4F46E5), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.itemName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'SL #${widget.product.slNo} • ${widget.product.barcode}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Remarks Text Box
            const Text(
              'Remarks / Notes:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _remarksController,
              maxLines: 3,
              style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
              decoration: InputDecoration(
                hintText: 'Enter stock availability notes or reasons for missing stock...',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ),
            const SizedBox(height: 18),

            // Images Attachment Section Header
            Row(
              children: [
                const Icon(Icons.photo_library_rounded, size: 18, color: Color(0xFF4F46E5)),
                const SizedBox(width: 8),
                const Text(
                  'Stock Photos / Evidence:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                ),
                const Spacer(),
                // Add Image Action Buttons
                TextButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_rounded, size: 16),
                  label: const Text('Camera', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                TextButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.image_rounded, size: 16),
                  label: const Text('Gallery', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Previews Grid / List
            if (_isLoadingImages)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ),
              )
            else ...[
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // New Images to Upload
                    ..._newImages.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final file = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF4F46E5), width: 1.5),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                File(file.path),
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: () => _removeNewImage(idx),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Existing Uploaded Images
                    ..._existingImageUrls.map((url) {
                      return Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            url,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8)),
                            ),
                          ),
                        ),
                      );
                    }),

                    // Empty Add Button Tile if no images
                    if (_newImages.isEmpty && _existingImageUrls.isEmpty)
                      InkWell(
                        onTap: () => _pickImage(ImageSource.camera),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 120,
                          height: 90,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_rounded, color: Color(0xFF64748B), size: 24),
                              SizedBox(height: 4),
                              Text('Add Photo', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Save / Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveRemarksAndUpload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text('Saving...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_rounded, size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Save Remark & Photos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
