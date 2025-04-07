import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';

class MetadataExtractor {
  /// Extract Open Graph metadata from a URL
  /// Returns a map with metadata or null if extraction fails
  Future<Map<String, String>?> extractMetadata(String url) async {
    try {
      // Make HTTP request to get the HTML content
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        print('Failed to load page: ${response.statusCode}');
        return null;
      }

      // Parse the HTML
      final document = parser.parse(response.body);

      // Extract metadata
      final metadata = {
        'url': url,
        'title':
            _getMetaContent(document, 'og:title') ?? _getTitle(document) ?? '',
        'description': _getMetaContent(document, 'og:description') ??
            _getMetaContent(document, 'description') ??
            '',
        'image': _getMetaContent(document, 'og:image') ?? '',
        'siteName': _getMetaContent(document, 'og:site_name') ?? '',
        'type': _getMetaContent(document, 'og:type') ?? '',
      };

      return metadata;
    } catch (e) {
      print('Error extracting metadata: $e');
      return null;
    }
  }

  /// Extract content from a meta tag with the specified property or name
  String? _getMetaContent(Document document, String property) {
    // Try with property attribute (Open Graph)
    final ogTag = document.querySelector('meta[property="$property"]');
    if (ogTag != null) {
      return ogTag.attributes['content'];
    }

    // Try with name attribute (traditional meta)
    final nameTag = document.querySelector('meta[name="$property"]');
    if (nameTag != null) {
      return nameTag.attributes['content'];
    }

    return null;
  }

  /// Extract title from the title tag
  String? _getTitle(Document document) {
    final titleTag = document.querySelector('title');
    return titleTag?.text;
  }

  /// Check if a string is a valid URL
  bool isValidUrl(String text) {
    try {
      final uri = Uri.parse(text);
      return uri.scheme == 'http' || uri.scheme == 'https';
    } catch (e) {
      return false;
    }
  }
}
