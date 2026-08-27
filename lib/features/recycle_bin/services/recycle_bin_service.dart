import 'dart:convert';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/core/config/api_config.dart';
import '../models/recycle_bin_item.dart';

class RecycleBinService {
  final AuthProvider authProvider;
  
  RecycleBinService(this.authProvider);

  String get token => authProvider.token ?? '';

  Future<List<RecycleBinItem>> getDeletedItems() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/recycle-bin'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List items = data['data'];
          return items.map((e) => RecycleBinItem.fromJson(e)).toList();
        }
      }
      throw Exception('Failed to load recycle bin items');
    } catch (e) {
      throw Exception('Error fetching recycle bin items: $e');
    }
  }

  Future<void> restoreItem(String entityType, int id) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/recycle-bin/restore/$entityType/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to restore item');
      }
    } catch (e) {
      throw Exception('Error restoring item: $e');
    }
  }

  Future<void> permanentlyDeleteItem(String entityType, int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/recycle-bin/permanent/$entityType/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to permanently delete item');
      }
    } catch (e) {
      throw Exception('Error deleting item: $e');
    }
  }

  Future<void> clearAllItems() async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/recycle-bin/clear'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to empty recycle bin');
      }
    } catch (e) {
      throw Exception('Error emptying recycle bin: $e');
    }
  }
}
