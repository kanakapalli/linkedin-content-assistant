  import 'package:flutter/material.dart';

class UrlPreviewCard extends StatelessWidget {
  final Map<String, String> metadata;

  const UrlPreviewCard({
    Key? key,
    required this.metadata,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Site name and link icon
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(Icons.link, size: 16, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  metadata['siteName'] ?? 'Web Link',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Image preview
          if (metadata['image']?.isNotEmpty == true)
            Container(
              height: 200,
              width: double.infinity,
              child: Image.network(
                metadata['image']!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey.shade800,
                  child: Center(
                    child: Icon(Icons.image_not_supported, size: 50),
                  ),
                ),
              ),
            ),

          // Title
          if (metadata['title']?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                metadata['title']!,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Description
          if (metadata['description']?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                metadata['description']!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade300,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // URL
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              metadata['url'] ?? '',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
