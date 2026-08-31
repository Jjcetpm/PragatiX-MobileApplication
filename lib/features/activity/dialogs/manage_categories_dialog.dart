import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/activity/models/activity_category_item.dart';
import 'package:pragatix/features/activity/providers/activity_provider.dart';

class ManageCategoriesDialog extends StatefulWidget {
  final ActivityProvider? provider;
  final Function(String selectedCategory)? onCategorySelected;

  const ManageCategoriesDialog({super.key, this.provider, this.onCategorySelected});

  static Future<String?> show(BuildContext context, {ActivityProvider? provider, Function(String)? onCategorySelected}) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ManageCategoriesDialog(provider: provider, onCategorySelected: onCategorySelected),
    );
  }

  @override
  State<ManageCategoriesDialog> createState() => _ManageCategoriesDialogState();
}

class _ManageCategoriesDialogState extends State<ManageCategoriesDialog> {
  final TextEditingController _newCatController = TextEditingController();
  final TextEditingController _newDescController = TextEditingController();

  bool _isAdding = false;
  String? _inlineError;

  ActivityProvider get _provider {
    if (widget.provider != null) return widget.provider!;
    return context.read<ActivityProvider>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.loadCategories();
    });
  }

  @override
  void dispose() {
    _newCatController.dispose();
    _newDescController.dispose();
    super.dispose();
  }

  Future<void> _handleAddCategory() async {
    final name = _newCatController.text.trim();
    if (name.isEmpty) {
      setState(() => _inlineError = 'Please enter a category name');
      return;
    }

    setState(() {
      _isAdding = true;
      _inlineError = null;
    });

    final newItem = await _provider.createCategory(
      name,
      description: _newDescController.text.trim().isNotEmpty ? _newDescController.text.trim() : null,
    );

    if (mounted) {
      setState(() => _isAdding = false);
      if (newItem != null) {
        _newCatController.clear();
        _newDescController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category "${newItem.name}" added successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        widget.onCategorySelected?.call(newItem.name);
      } else {
        setState(() {
          _inlineError = _provider.error ?? 'Failed to add category';
        });
      }
    }
  }

  Future<void> _handleEditCategory(ActivityCategoryItem cat) async {
    final editController = TextEditingController(text: cat.name);
    final descController = TextEditingController(text: cat.description ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_rounded, color: Color(0xFFEA4335), size: 22),
            SizedBox(width: 8),
            Text('Edit Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: editController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Category Name *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA4335),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && editController.text.trim().isNotEmpty && mounted) {
      final updated = await _provider.updateCategory(
        cat.id,
        editController.text.trim(),
        description: descController.text.trim(),
      );
      if (mounted) {
        if (updated != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Category updated to "${updated.name}"'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          final err = _provider.error ?? 'Update failed';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _handleDeleteCategory(ActivityCategoryItem cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text('Delete Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Move category "${cat.name}" to Recycle Bin?\n\n'
          'You can restore it anytime from the Recycle Bin.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Move to Bin'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final ok = await _provider.deleteCategory(cat.id);
      if (mounted) {
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Category "${cat.name}" moved to Recycle Bin'),
              backgroundColor: Colors.orange.shade800,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          final err = _provider.error ?? 'Failed to delete';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _provider,
      builder: (context, _) {
        final categories = _provider.activityCategories;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 6,
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── HEADER ──────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA4335).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.category_rounded, color: Color(0xFFEA4335), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Manage XP Categories',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      Text(
                        '${categories.length} categories configured',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  splashRadius: 20,
                ),
              ],
            ),
            const Divider(height: 24),

            // ── ADD NEW CATEGORY INPUT ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ADD NEW CATEGORY',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newCatController,
                          decoration: InputDecoration(
                            hintText: 'e.g. Hackathon, Research',
                            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          onSubmitted: (_) => _handleAddCategory(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _isAdding ? null : _handleAddCategory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA4335),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        icon: _isAdding
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                  if (_inlineError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _inlineError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── CATEGORIES LIST ─────────────────────────────────────────────
            const Text(
              'ACTIVE CATEGORIES',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: categories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.category_outlined, size: 40, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text('No categories found', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: categories.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 6),
                      itemBuilder: (context, idx) {
                        final cat = categories[idx];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B).withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.label_rounded, size: 16, color: Color(0xFF1E293B)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cat.name,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E293B)),
                                    ),
                                    if (cat.description != null && cat.description!.isNotEmpty)
                                      Text(
                                        cat.description!,
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              // Select action
                              if (widget.onCategorySelected != null)
                                InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  onTap: () {
                                    widget.onCategorySelected!(cat.name);
                                    Navigator.pop(context, cat.name);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    margin: const EdgeInsets.only(right: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.green.shade200),
                                    ),
                                    child: Text(
                                      'Use',
                                      style: TextStyle(color: Colors.green.shade800, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              // Edit button
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blueGrey),
                                tooltip: 'Edit Name',
                                splashRadius: 18,
                                onPressed: () => _handleEditCategory(cat),
                              ),
                              // Delete button
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                tooltip: 'Move to Recycle Bin',
                                splashRadius: 18,
                                onPressed: () => _handleDeleteCategory(cat),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 8),
            // ── RECYCLE BIN FOOTNOTE ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: Colors.blue.shade800),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Deleted categories can be restored anytime from the Recycle Bin.',
                      style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  },
);
  }
}
