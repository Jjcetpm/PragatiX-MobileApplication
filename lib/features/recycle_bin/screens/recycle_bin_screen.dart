import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import '../models/recycle_bin_item.dart';
import '../services/recycle_bin_service.dart';

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  late RecycleBinService _service;
  List<RecycleBinItem> _items = [];
  bool _isLoading = true;
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _service = RecycleBinService(authProvider);
    _fetchItems();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _fetchItems() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final items = await _service.getDeletedItems();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Failed to load recycle bin items: $e', isError: true);
    }
  }

  Future<void> _restoreItem(RecycleBinItem item) async {
    try {
      await _service.restoreItem(item.entityType, item.id);
      _showSnackBar('${_formatEntityType(item.entityType)} restored successfully!');
      _fetchItems();
    } catch (e) {
      _showSnackBar('Failed to restore: $e', isError: true);
    }
  }

  Future<void> _deletePermanently(RecycleBinItem item) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 24),
            SizedBox(width: 10),
            Text(
              'Delete Permanently?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${item.entityName}" (${_formatEntityType(item.entityType)})?\n\nThis action cannot be undone.',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Permanently', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.permanentlyDeleteItem(item.entityType, item.id);
        _showSnackBar('${_formatEntityType(item.entityType)} permanently deleted');
        _fetchItems();
      } catch (e) {
        _showSnackBar('Failed to delete permanently: $e', isError: true);
      }
    }
  }

  Future<void> _clearRecycleBin() async {
    if (_items.isEmpty) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
            SizedBox(width: 10),
            Text('Empty Recycle Bin?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete all ${_items.length} items in the Recycle Bin?\n\nThis action is irreversible.',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Empty Recycle Bin', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _service.clearAllItems();
        _showSnackBar('Recycle Bin emptied successfully!');
        _fetchItems();
      } catch (e) {
        _showSnackBar('Failed to empty recycle bin: $e', isError: true);
        _fetchItems();
      }
    }
  }

  String _formatEntityType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : '')
        .join(' ');
  }

  IconData _getEntityIcon(String type) {
    final upper = type.toUpperCase();
    if (upper.contains('CATEGORY')) return Icons.category_rounded;
    if (upper.contains('EVIDENCE')) return Icons.description_outlined;
    if (upper.contains('STUDENT')) return Icons.school_rounded;
    if (upper.contains('TEACHER') || upper.contains('FACULTY')) return Icons.person_outline_rounded;
    if (upper.contains('LEVEL')) return Icons.military_tech_rounded;
    if (upper.contains('BADGE')) return Icons.verified_rounded;
    if (upper.contains('TEAM') || upper.contains('GROUP')) return Icons.groups_rounded;
    if (upper.contains('STAGE')) return Icons.stairs_rounded;
    if (upper.contains('ACTIVITY')) return Icons.local_activity_rounded;
    if (upper.contains('SECTION')) return Icons.grid_view_rounded;
    return Icons.delete_outline_rounded;
  }

  Color _getEntityColor(String type) {
    final upper = type.toUpperCase();
    if (upper.contains('CATEGORY')) return const Color(0xFF6366F1);
    if (upper.contains('EVIDENCE')) return const Color(0xFF0EA5E9);
    if (upper.contains('STUDENT')) return const Color(0xFF2563EB);
    if (upper.contains('TEACHER') || upper.contains('FACULTY')) return const Color(0xFF8B5CF6);
    if (upper.contains('LEVEL')) return const Color(0xFFD97706);
    if (upper.contains('BADGE')) return const Color(0xFF16A34A);
    if (upper.contains('STAGE')) return const Color(0xFFF59E0B);
    if (upper.contains('SECTION')) return const Color(0xFF0D9488);
    return const Color(0xFF64748B);
  }

  void _showItemDetailsModal(RecycleBinItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entityColor = _getEntityColor(item.entityType);
    final entityIcon = _getEntityIcon(item.entityType);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: entityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(entityIcon, color: entityColor, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.entityName,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: entityColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _formatEntityType(item.entityType).toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: entityColor,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Detailed information rows
              if (item.originalLocation != null && item.originalLocation!.isNotEmpty)
                _buildDetailRow(
                  icon: Icons.account_tree_outlined,
                  label: 'Original Location / Context',
                  value: item.originalLocation!,
                  isDark: isDark,
                  iconColor: const Color(0xFF2563EB),
                ),
              if (item.description != null && item.description!.isNotEmpty)
                _buildDetailRow(
                  icon: Icons.info_outline_rounded,
                  label: 'Description / What It Is',
                  value: item.description!,
                  isDark: isDark,
                  iconColor: const Color(0xFF0EA5E9),
                ),
              _buildDetailRow(
                icon: Icons.person_outline_rounded,
                label: 'Deleted By',
                value: item.deletedBy?.isNotEmpty == true ? item.deletedBy! : 'Admin / System',
                isDark: isDark,
                iconColor: const Color(0xFF8B5CF6),
              ),
              if (item.deletedAt != null)
                _buildDetailRow(
                  icon: Icons.access_time_rounded,
                  label: 'Deleted At',
                  value: DateFormat('yyyy-MM-dd HH:mm:ss').format(item.deletedAt!),
                  isDark: isDark,
                  iconColor: const Color(0xFF64748B),
                ),
              if (item.permanentDeleteAt != null)
                _buildDetailRow(
                  icon: Icons.timer_outlined,
                  label: 'Scheduled Auto-Purge',
                  value: DateFormat('yyyy-MM-dd HH:mm').format(item.permanentDeleteAt!),
                  isDark: isDark,
                  iconColor: const Color(0xFFD97706),
                ),

              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _deletePermanently(item);
                      },
                      icon: const Icon(Icons.delete_forever_rounded, size: 18),
                      label: const Text('Delete Permanently', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _restoreItem(item);
                      },
                      icon: const Icon(Icons.restore_rounded, size: 18),
                      label: const Text('Restore Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final categories = <String>{'ALL'};
    for (var item in _items) {
      if (item.entityType.isNotEmpty) {
        categories.add(item.entityType);
      }
    }

    final filteredItems = _selectedFilter == 'ALL'
        ? _items
        : _items.where((i) => i.entityType == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Recycle Bin',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
              tooltip: 'Empty Recycle Bin',
              onPressed: _clearRecycleBin,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: _fetchItems,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Info Header Banner ─────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
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
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_delete_outlined,
                          color: Color(0xFF2563EB),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Retention Policy',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_items.length} items',
                                    style: const TextStyle(
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tap any card to view details, location, and deletion logs.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Filter Chips (When multiple types exist) ───────────────────
                if (categories.length > 2)
                  Container(
                    height: 38,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: categories.map((cat) {
                        final isSelected = _selectedFilter == cat;
                        final label = cat == 'ALL' ? 'All Items (${_items.length})' : _formatEntityType(cat);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: const Color(0xFF2563EB),
                            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            onSelected: (_) {
                              setState(() => _selectedFilter = cat);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                // ── List / Empty View ──────────────────────────────────────────
                Expanded(
                  child: filteredItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Image.asset(
                                    'assets/images/recycle_bin_empty.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Recycle Bin is Empty',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Deleted items will appear here for safe restoration.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchItems,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: filteredItems.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              final entityColor = _getEntityColor(item.entityType);
                              final entityIcon = _getEntityIcon(item.entityType);

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _showItemDetailsModal(item),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.02),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Entity Icon Container
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: entityColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(entityIcon, color: entityColor, size: 22),
                                        ),
                                        const SizedBox(width: 14),

                                        // Content Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      item.entityName,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15,
                                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: entityColor.withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      _formatEntityType(item.entityType).toUpperCase(),
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: entityColor,
                                                        letterSpacing: 0.3,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              // Location Info (enga irunthuthu)
                                              if (item.originalLocation != null && item.originalLocation!.isNotEmpty) ...[
                                                const SizedBox(height: 5),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.account_tree_outlined,
                                                      size: 13,
                                                      color: Color(0xFF2563EB),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        item.originalLocation!,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],

                                              // Description (athu enna)
                                              if (item.description != null && item.description!.isNotEmpty) ...[
                                                const SizedBox(height: 3),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.info_outline_rounded,
                                                      size: 13,
                                                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        item.description!,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],

                                              // Deleted By (yaru delete panna)
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.person_outline_rounded,
                                                    size: 13,
                                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Deleted by: ${item.deletedBy?.isNotEmpty == true ? item.deletedBy! : 'Admin'}',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w500,
                                                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  if (item.deletedAt != null) ...[
                                                    Icon(
                                                      Icons.access_time_rounded,
                                                      size: 12,
                                                      color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      DateFormat('yyyy-MM-dd HH:mm').format(item.deletedAt!),
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                                                      ),
                                                    ),
                                                  ],
                                                  if (item.permanentDeleteAt != null) ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFFEF3C7),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        'Purge: ${DateFormat('MM-dd').format(item.permanentDeleteAt!)}',
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w700,
                                                          color: Color(0xFFD97706),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),

                                        // Action Buttons
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius: BorderRadius.circular(8),
                                                onTap: () => _restoreItem(item),
                                                child: Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFDCFCE7),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Icon(
                                                    Icons.restore_rounded,
                                                    color: Color(0xFF16A34A),
                                                    size: 18,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius: BorderRadius.circular(8),
                                                onTap: () => _deletePermanently(item),
                                                child: Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFEE2E2),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Icon(
                                                    Icons.delete_forever_rounded,
                                                    color: Color(0xFFDC2626),
                                                    size: 18,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
