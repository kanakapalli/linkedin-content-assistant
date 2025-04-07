import 'dart:convert';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class SharedItem {
  final String? path;
  final String? mimeType;
  final SharedMediaType type;
  final Map<String, String>? metadata;
  final DateTime timestamp;
  final String id;

  SharedItem({
    this.path,
    this.mimeType,
    required this.type,
    this.metadata,
    required this.timestamp,
    required this.id,
  });

  factory SharedItem.fromSharedMediaFile(
    SharedMediaFile file, {
    Map<String, String>? metadata,
  }) {
    return SharedItem(
      path: file.path,
      mimeType: file.mimeType,
      type: file.type,
      metadata: metadata,
      timestamp: DateTime.now(),
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'mimeType': mimeType,
      'type': type.toString(),
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'id': id,
    };
  }

  // Create from storage map
  factory SharedItem.fromMap(Map<String, dynamic> map) {
    return SharedItem(
      path: map['path'],
      mimeType: map['mimeType'],
      type: _getTypeFromString(map['type']),
      metadata: map['metadata'] != null
          ? Map<String, String>.from(map['metadata'])
          : null,
      timestamp: DateTime.parse(map['timestamp']),
      id: map['id'],
    );
  }

  // Helper to convert type string back to enum
  static SharedMediaType _getTypeFromString(String typeString) {
    switch (typeString) {
      case 'SharedMediaType.image':
        return SharedMediaType.image;
      case 'SharedMediaType.video':
        return SharedMediaType.video;
      case 'SharedMediaType.file':
        return SharedMediaType.file;
      case 'SharedMediaType.text':
        return SharedMediaType.text;
      default:
        return SharedMediaType.text;
    }
  }

  // Encode to JSON
  String toJson() => json.encode(toMap());

  // Decode from JSON
  factory SharedItem.fromJson(String source) =>
      SharedItem.fromMap(json.decode(source));
}
