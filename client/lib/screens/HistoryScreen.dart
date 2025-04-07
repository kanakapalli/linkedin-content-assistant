import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:receive_sharing_intent_example/services/MetadataExtractor.dart';
import 'package:receive_sharing_intent_example/services/storage/SharedItemStorage.dart';
import '../models/SharedItem.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<SharedItem> _sharedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSharedItems();
  }

  Future<void> _loadSharedItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await SharedItemStorage.getItems();

      // Sort by timestamp (newest first)
      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        _sharedItems = items;
      });
    } catch (e) {
      print("Error loading shared items: $e");
      // Show error if needed
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteItem(String id) async {
    try {
      await SharedItemStorage.deleteItem(id);
      // Refresh the list
      await _loadSharedItems();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item deleted')),
      );
    } catch (e) {
      print("Error deleting item: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting item')),
      );
    }
  }

  Future<void> _clearAllItems() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear History'),
        content: Text('Are you sure you want to delete all shared items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('DELETE ALL'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await SharedItemStorage.clearItems();
        await _loadSharedItems();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('All items deleted')),
        );
      } catch (e) {
        print("Error clearing items: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing items')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sharing History'),
        actions: [
          if (_sharedItems.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep),
              onPressed: _clearAllItems,
              tooltip: 'Clear all',
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _sharedItems.isEmpty
              ? _buildEmptyHistory()
              : _buildHistoryList(),
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "No sharing history",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            "Items shared to this app will appear here",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return RefreshIndicator(
      onRefresh: _loadSharedItems,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _sharedItems.length,
        itemBuilder: (context, index) {
          final item = _sharedItems[index];
          return _buildHistoryItem(item);
        },
      ),
    );
  }

  Widget _buildHistoryItem(SharedItem item) {
    final isUrl = item.path != null &&
        (item.path!.startsWith('http://') || item.path!.startsWith('https://'));
    final isImage = item.mimeType?.startsWith('image/') ?? false;
    final hasMetadata = item.metadata != null && item.metadata!.isNotEmpty;

    return Dismissible(
      key: Key(item.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _deleteItem(item.id);
      },
      child: Card(
        margin: EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with date/time and icon
            Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  // Icon based on content type
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Icon(
                        isImage
                            ? Icons.image
                            : isUrl
                                ? Icons.link
                                : item.type == SharedMediaType.text
                                    ? Icons.description
                                    : Icons.insert_drive_file,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),

                  // Date and time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('MMM d, yyyy').format(item.timestamp),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('h:mm a').format(item.timestamp),
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Delete button
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteItem(item.id),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ),

            // Content preview
            if (hasMetadata && item.metadata!['title'] != null) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  item.metadata!['title']!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: 8),
            ],

            if (isImage && item.path != null) ...[
              Image.file(
                File(item.path!),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 100,
                  color: Colors.grey.shade200,
                  child: Center(child: Icon(Icons.broken_image)),
                ),
              ),
            ] else if (hasMetadata && item.metadata!['image'] != null) ...[
              Image.network(
                item.metadata!['image']!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 100,
                  color: Colors.grey.shade200,
                  child: Center(child: Icon(Icons.broken_image)),
                ),
              ),
            ] else ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.path ?? "No content",
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],

            // Path or URL
            if (item.path != null) ...[
              Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.link, size: 14, color: Colors.grey),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isUrl ? _getDisplayUrl(item.path!) : "Local file",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // View details button
            Padding(
              padding: EdgeInsets.all(12),
              child: OutlinedButton(
                onPressed: () => _showItemDetails(context, item),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: 16),
                    SizedBox(width: 8),
                    Text("View Details"),
                  ],
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDisplayUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return url;
    }
  }

  void _showItemDetails(BuildContext context, SharedItem item) {
    final isUrl = item.path != null &&
        (item.path!.startsWith('http://') || item.path!.startsWith('https://'));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade600,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Title
                      Row(
                        children: [
                          Icon(
                            isUrl
                                ? Icons.link
                                : item.type == SharedMediaType.text
                                    ? Icons.description
                                    : item.mimeType?.startsWith('image/') ==
                                            true
                                        ? Icons.image
                                        : Icons.insert_drive_file,
                            color: Colors.blue,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Shared Content Details",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 24),

                      // Date and time
                      _buildDetailSection(
                        "Timestamp",
                        [
                          _buildDetailItem(
                              "Date",
                              DateFormat('MMMM d, yyyy')
                                  .format(item.timestamp)),
                          _buildDetailItem("Time",
                              DateFormat('h:mm:ss a').format(item.timestamp)),
                        ],
                      ),

                      SizedBox(height: 16),

                      // File information section
                      _buildDetailSection(
                        "File Information",
                        [
                          _buildDetailItem("Type", item.type.toString()),
                          _buildDetailItem(
                              "MIME Type", item.mimeType ?? "Unknown"),
                          _buildDetailItem("Path", item.path ?? "N/A"),
                        ],
                      ),

                      // Metadata section if available
                      if (item.metadata != null &&
                          item.metadata!.isNotEmpty) ...[
                        SizedBox(height: 16),
                        _buildDetailSection(
                          "Extracted Metadata",
                          item.metadata!.entries
                              .map((entry) =>
                                  _buildDetailItem(entry.key, entry.value))
                              .toList(),
                        ),
                      ],

                      // Content Preview
                      SizedBox(height: 16),
                      Text(
                        "Content Preview",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),

                      // Display content based on type
                      if (item.mimeType?.startsWith('image/') == true &&
                          item.path != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(item.path!),
                            fit: BoxFit.contain,
                            width: double.infinity,
                          ),
                        ),
                      ] else if (isUrl &&
                          item.metadata != null &&
                          item.metadata!['image'] != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.metadata!['image']!,
                            fit: BoxFit.contain,
                            width: double.infinity,
                          ),
                        ),
                      ] else if (item.path != null) ...[
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(item.path!),
                        ),
                      ],

                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        ...items,
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 4),
          SelectableText(
            value,
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
