import 'package:receive_sharing_intent_example/models/SharedItem.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SharedItemStorage {
  static const String _storageKey = 'shared_items';

  // Save a shared item
  static Future<bool> saveItem(SharedItem item) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing items
    List<SharedItem> items = await getItems();

    // Add new item
    items.add(item);

    // Convert to JSON list
    final List<String> jsonItems = items.map((item) => item.toJson()).toList();

    // Save to storage
    return await prefs.setStringList(_storageKey, jsonItems);
  }

  // Get all shared items
  static Future<List<SharedItem>> getItems() async {
    final prefs = await SharedPreferences.getInstance();

    // Get stored JSON strings
    final List<String>? jsonItems = prefs.getStringList(_storageKey);

    if (jsonItems == null || jsonItems.isEmpty) {
      return [];
    }

    // Convert to SharedItem objects
    return jsonItems
        .map((jsonString) => SharedItem.fromJson(jsonString))
        .toList();
  }

  // Delete a shared item by id
  static Future<bool> deleteItem(String id) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing items
    List<SharedItem> items = await getItems();

    // Remove item with matching id
    items.removeWhere((item) => item.id == id);

    // Convert to JSON list
    final List<String> jsonItems = items.map((item) => item.toJson()).toList();

    // Save to storage
    return await prefs.setStringList(_storageKey, jsonItems);
  }

  // Clear all shared items
  static Future<bool> clearItems() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(_storageKey);
  }
}
