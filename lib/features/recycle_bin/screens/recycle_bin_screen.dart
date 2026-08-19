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
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
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
      _showSnackBar('${item.entityType} restored successfully!');
      _fetchItems();
    } catch (e) {
      _showSnackBar('Failed to restore: $e', isError: true);
    }
  }

  Future<void> _deletePermanently(RecycleBinItem item) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Permanently?'),
        content: Text('Are you sure you want to permanently delete this ${item.entityType.toLowerCase()}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.permanentlyDeleteItem(item.entityType, item.id);
        _showSnackBar('${item.entityType} permanently deleted');
        _fetchItems();
      } catch (e) {
        _showSnackBar('Failed to delete permanently: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycle Bin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchItems,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('Recycle Bin is empty', style: TextStyle(fontSize: 18, color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.shade100,
                          child: const Icon(Icons.delete_outline, color: Colors.red),
                        ),
                        title: Text(item.entityName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Type: ${item.entityType}'),
                            if (item.deletedAt != null)
                              Text('Deleted: ${DateFormat('yyyy-MM-dd HH:mm').format(item.deletedAt!)}'),
                            if (item.permanentDeleteAt != null)
                              Text('Auto-purge: ${DateFormat('yyyy-MM-dd').format(item.permanentDeleteAt!)}', 
                                style: TextStyle(color: Colors.orange.shade700, fontSize: 12)),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.restore, color: Colors.green),
                              tooltip: 'Restore',
                              onPressed: () => _restoreItem(item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_forever, color: Colors.red),
                              tooltip: 'Delete Permanently',
                              onPressed: () => _deletePermanently(item),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
