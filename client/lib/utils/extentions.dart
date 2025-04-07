import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:io';

/// Extension to add helper methods to SharedMediaFile for extracting metadata
extension SharedMediaFileExtension on SharedMediaFile {
  /// Check if the file represents a URL
  bool get isUrl =>
      (path.startsWith('http://') || path.startsWith('https://'));

  /// Check if the file is an image
  bool get isImage => mimeType?.startsWith('image/') == true;

  /// Check if the file is a text file
  bool get isText => type == SharedMediaType.text;

  /// Get the content type description
  String get contentType {
    if (isUrl) return "URL";
    if (isImage) return "Image";
    if (isText) return "Text";
    return mimeType ?? "Unknown type";
  }

  /// Get the image URL or path
  Future<String?> get image async {
    if (isImage) {
      return path;
    }
    return null;
  }

  /// Get the title from URL metadata or a default title based on type
  String get title {
    // This would need to access the URL metadata from outside
    // Placeholder for demonstration purposes
    return "Default Title";
  }

  /// Get the description from URL metadata or text content
  Future<String> get description async {
    if (isText && !isUrl) {
      try {
        final file = File(path);
        return await file.readAsString();
      } catch (e) {
        return "Error reading text: $e";
      }
    }
    return "No description available";
  }

  /// Get basic content information as a map
  Future<Map<String, String>> getContentInfo(
      Map<String, Map<String, String>> urlMetadata) async {
    String title = "No title";
    String description = "No description";
    String imageUrl = "No image";
    String additionalInfo = "";

    final String path = this.path ?? "No path";

    if (isUrl && urlMetadata.containsKey(path)) {
      // Get metadata for URL content
      final metadata = urlMetadata[path]!;
      title = metadata['title'] ?? title;
      description = metadata['description'] ?? description;
      imageUrl = metadata['image'] ?? imageUrl;
      additionalInfo = "URL: $path";
    } else if (isText && !isUrl) {
      // Get content for text files
      try {
        final file = File(path);
        final content = await file.readAsString();
        description = content;
        additionalInfo = "File path: $path";
      } catch (e) {
        additionalInfo = "Error reading text file: $e";
      }
    } else if (isImage) {
      // Get info for image files
      title = "Image";
      description = "Image file";
      imageUrl = path;
      additionalInfo = "File path: $path";
    } else {
      // For other file types
      additionalInfo =
          "File path: $path\nFile type: $type\nMIME type: $mimeType";
    }

    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'contentType': contentType,
      'additionalInfo': additionalInfo,
    };
  }
}
