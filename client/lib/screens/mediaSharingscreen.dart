import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:receive_sharing_intent_example/models/SharedItem.dart';
import 'package:receive_sharing_intent_example/screens/CommentGeneratorScreen.dart';
import 'package:receive_sharing_intent_example/screens/HistoryScreen.dart';
import 'package:receive_sharing_intent_example/screens/linkedinShareScreen.dart';
import 'package:receive_sharing_intent_example/services/MetadataExtractor.dart';
import 'package:receive_sharing_intent_example/services/openAi.dart';
import 'package:receive_sharing_intent_example/services/share_helper.dart';
import 'package:receive_sharing_intent_example/services/storage/SharedItemStorage.dart';
import 'package:receive_sharing_intent_example/utils/extentions.dart';
import 'package:receive_sharing_intent_example/widgets/UrlPreviewCard.dart';

class MediaSharingScreen extends StatefulWidget {
  @override
  _MediaSharingScreenState createState() => _MediaSharingScreenState();
}

class _MediaSharingScreenState extends State<MediaSharingScreen> {
  late StreamSubscription _intentSub;
  final _sharedFiles = <SharedMediaFile>[];
  final MetadataExtractor _metadataExtractor = MetadataExtractor();
  bool _isLoading = false;

  // Store metadata for shared items
  Map<String, Map<String, String>?> _urlMetadata = {};
  Map<String, bool> _isLoadingMetadata = {};

  @override
  void initState() {
    super.initState();
    initOpenAI();
    // Listen to media sharing coming from outside the app while the app is in the memory
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((value) {
      setState(() {
        _sharedFiles.clear();
        _sharedFiles.addAll(value);
        print(_sharedFiles.map((f) => f.toMap()));
      });

      // Process the shared files to extract metadata
      if (value.isNotEmpty) {
        _processSharedFiles(value);
      }
    }, onError: (err) {
      print("getIntentDataStream error: $err");
    });

    // Get the media sharing coming from outside the app while the app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      setState(() {
        _sharedFiles.clear();
        _sharedFiles.addAll(value);
        print(_sharedFiles.map((f) => f.toMap()));
      });

      // Process the shared files to extract metadata
      if (value.isNotEmpty) {
        _processSharedFiles(value);
      }

      // Tell the library that we are done processing the intent
      ReceiveSharingIntent.instance.reset();
    });
  }

  // Process shared files to extract metadata and save to storage
  void _processSharedFiles(List<SharedMediaFile> files) {
    for (final file in files) {
      if (_isUrl(file.path)) {
        // It's a URL, extract metadata immediately
        _extractAndSaveMetadata(file);
      } else if (file.type == SharedMediaType.text) {
        // It's a text file, check if it contains a URL
        _checkTextFileForUrl(file);
      } else {
        // Save other types directly
        _saveSharedItem(file, null);
      }
    }
  }

  bool _isUrl(String text) {
    return text.startsWith('http://') || text.startsWith('https://');
  }

  // Check if a text file contains a URL
  Future<void> _checkTextFileForUrl(SharedMediaFile file) async {
    try {
      final fileObj = File(file.path);
      final text = await fileObj.readAsString();

      if (_isUrl(text)) {
        // Create a new "virtual" SharedMediaFile for the URL
        final urlFile = SharedMediaFile(
          path: text,
          type: file.type,
          mimeType: 'text/plain',
        );

        // Extract metadata for this URL
        _extractAndSaveMetadata(urlFile);
      } else {
        // Just a regular text file, save it
        _saveSharedItem(file, null);
      }
    } catch (e) {
      print("Error reading text file: $e");
      // Save original file anyway
      _saveSharedItem(file, null);
    }
  }

  // Extract metadata from a URL and save item
  Future<void> _extractAndSaveMetadata(SharedMediaFile file) async {
    if (_urlMetadata.containsKey(file.path) ||
        _isLoadingMetadata[file.path] == true) {
      return;
    }

    setState(() {
      _isLoadingMetadata[file.path] = true;
    });

    try {
      final metadata = await _metadataExtractor.extractMetadata(file.path);

      setState(() {
        _urlMetadata[file.path] = metadata;
        _isLoadingMetadata[file.path] = false;
      });

      // Save to storage with metadata
      _saveSharedItem(file, metadata);
    } catch (e) {
      print("Error extracting metadata: $e");
      setState(() {
        _isLoadingMetadata[file.path] = false;
      });

      // Save to storage without metadata
      _saveSharedItem(file, null);
    }
  }

  // Save shared item to storage
  Future<void> _saveSharedItem(
      SharedMediaFile file, Map<String, String>? metadata) async {
    final item = SharedItem.fromSharedMediaFile(file, metadata: metadata);

    try {
      await SharedItemStorage.saveItem(item);
    } catch (e) {
      print("Error saving shared item: $e");
    }
  }

  @override
  void dispose() {
    _intentSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Content'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HistoryScreen()),
              );
            },
            tooltip: 'View History',
          ),
        ],
      ),
      body:
          _sharedFiles.isEmpty ? _buildEmptyState() : _buildSharedContentList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.share, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "No shared content yet",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            "Share content from other apps to see it here",
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HistoryScreen()),
              );
            },
            icon: Icon(Icons.history),
            label: Text("View History"),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LinkedInShareScreen()),
              );
            },
            icon: Icon(Icons.history),
            label: Text("Create New Post"),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => CommentGeneratorScreen()),
              );
            },
            icon: Icon(Icons.history),
            label: Text("Comment Generator"),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedContentList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _sharedFiles.length,
      itemBuilder: (context, index) {
        final file = _sharedFiles[index];
        return _buildSharedItemCard(file);
      },
    );
  }

  Widget _buildSharedItemCard(SharedMediaFile file) {
    final String path = file.path ?? "No path";
    final isImage = file.mimeType?.startsWith('image/') ?? false;
    final isUrl = _isUrl(path);
    final hasMetadata = _urlMetadata.containsKey(path);
    final isLoadingMetadata = _isLoadingMetadata[path] ?? false;

    // Check if this is a text file containing a URL
    bool isTextWithMetadata = false;
    String? urlFromText;

    if (file.type == SharedMediaType.text && !isUrl) {
      // Look for URLs in the text that might have metadata
      _urlMetadata.keys.forEach((url) {
        if (_isUrl(url) && !url.startsWith(path)) {
          isTextWithMetadata = true;
          urlFromText = url;
        }
      });
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show LinkedIn-style post layout
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon based on file type
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Icon(
                      isImage
                          ? Icons.image
                          : isUrl
                              ? Icons.link
                              : file.type == SharedMediaType.text
                                  ? Icons.description
                                  : Icons.insert_drive_file,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                  ),
                ),
                SizedBox(width: 12),

                // Title and details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Shared ${isImage ? 'Image' : isUrl ? 'Link' : 'Content'}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        file.mimeType ?? "Unknown type",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Loading indicator if extracting metadata
          if (isLoadingMetadata) ...[
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text("Getting link information..."),
                  ],
                ),
              ),
            ),
          ],

          // Display metadata if available (LinkedIn style)
          if ((isUrl || isTextWithMetadata) && !isLoadingMetadata) ...[
            _buildLinkedInStyleContent(
              isUrl ? path : urlFromText!,
              _urlMetadata[isUrl ? path : urlFromText] ?? {},
            ),
          ],

          // Display image preview
          if (isImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(file.path),
                fit: BoxFit.cover,
                width: double.infinity,
                height: 240,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey.shade200,
                  child: Center(
                    child:
                        Icon(Icons.broken_image, size: 48, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],

          // Display text preview if not URL or image
          if (file.type == SharedMediaType.text &&
              !isUrl &&
              !isTextWithMetadata) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: FutureBuilder<String>(
                future: _readTextFile(path),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final content = snapshot.data ?? "Unable to read content";
                  return Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      content,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
          ],

          // Action buttons
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // See full data button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showFullDataBottomSheet(context, file),
                    icon: Icon(Icons.info_outline),
                    label: Text("See Full Data"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 12),

                // Repost button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _repostContent(file),
                    icon: Icon(Icons.share),
                    label: Text("Repost"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              // Generate Comment button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommentGeneratorScreen(),
                      ),
                    );
                  },
                  icon: Icon(Icons.chat_bubble_outline),
                  label: Text("Generate Comment"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              SizedBox(width: 12),

              // Download Video button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.download),
                  label: Text("Download Video"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedInStyleContent(String url, Map<String, String> metadata) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title if available
        if (metadata['title']?.isNotEmpty == true) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
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
          SizedBox(height: 8),
        ],

        // Description if available
        if (metadata['description']?.isNotEmpty == true) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              metadata['description']!,
              style: TextStyle(fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: 12),
        ],

        // Image if available
        if (metadata['image']?.isNotEmpty == true) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              metadata['image']!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 100,
                color: Colors.grey.shade200,
                child: Center(
                  child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                ),
              ),
            ),
          ),
          SizedBox(height: 12),
        ],

        // URL source
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.link, size: 16, color: Colors.grey),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  metadata['siteName'] ?? _getDisplayUrl(url),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
      ],
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

  Future<String> _readTextFile(String path) async {
    try {
      final file = File(path);
      return await file.readAsString();
    } catch (e) {
      return "Error reading file: $e";
    }
  }

  void _showFullDataBottomSheet(BuildContext context, SharedMediaFile file) {
    final String path = file.path ?? "No path";
    final isUrl = _isUrl(path);

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
                                : file.type == SharedMediaType.text
                                    ? Icons.description
                                    : file.mimeType?.startsWith('image/') ==
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

                      // File information section
                      _buildDetailSection(
                        "File Information",
                        [
                          _buildDetailItem("Type", file.type.toString()),
                          _buildDetailItem(
                              "MIME Type", file.mimeType ?? "Unknown"),
                          _buildDetailItem("Path", path),
                          if (file.thumbnail != null)
                            _buildDetailItem("Has Thumbnail", "Yes"),
                          if (file.duration != null)
                            _buildDetailItem("Duration", "${file.duration} ms"),
                        ],
                      ),

                      // Extracted metadata section for URLs
                      if (isUrl && _urlMetadata.containsKey(path)) ...[
                        SizedBox(height: 16),
                        _buildDetailSection(
                          "Extracted Metadata",
                          _urlMetadata[path]!
                              .entries
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
                      if (file.mimeType?.startsWith('image/') == true) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(file.path),
                            fit: BoxFit.contain,
                            width: double.infinity,
                          ),
                        ),
                      ] else if (file.type == SharedMediaType.text &&
                          !isUrl) ...[
                        FutureBuilder<String>(
                          future: _readTextFile(path),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }

                            final content =
                                snapshot.data ?? "Unable to read content";
                            return Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SelectableText(content),
                            );
                          },
                        ),
                      ] else if (isUrl &&
                          _urlMetadata.containsKey(path) &&
                          _urlMetadata[path]!['image']?.isNotEmpty == true) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _urlMetadata[path]!['image']!,
                            fit: BoxFit.contain,
                            width: double.infinity,
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(path),
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

// Repost the content by printing title, description, image
  Future<void> _repostContent(SharedMediaFile file) async {
    // Initialize variables to store the content information
    String title = "No title";
    String description = "No description";
    String imageUrl = "No image";
    String contentType = "Unknown";
    String additionalInfo = "";
    bool success = true;

    try {
      final String path = file.path ?? "No path";
      final isUrl = _isUrl(path);

      // Set the content type based on file information
      if (isUrl) {
        contentType = "URL";
      } else if (file.mimeType?.startsWith('image/') == true) {
        contentType = "Image";
        imageUrl = path;
      } else if (file.type == SharedMediaType.text) {
        contentType = "Text";
      } else {
        contentType = file.mimeType ?? "Unknown type";
      }

      // Extract information based on content type
      if (isUrl && _urlMetadata.containsKey(path)) {
        // Get metadata for URL content
        final metadata = _urlMetadata[path]!;
        title = metadata['title'] ?? title;
        description = metadata['description'] ?? description;
        imageUrl = metadata['image'] ?? imageUrl;
        additionalInfo = "URL: $path";
      } else if (file.type == SharedMediaType.text && !isUrl) {
        // Get content for text files
        try {
          final content = await _readTextFile(path);
          description = content;
          additionalInfo = "File path: $path";
        } catch (e) {
          success = false;
          additionalInfo = "Error reading text file: $e";
        }
      } else if (file.mimeType?.startsWith('image/') == true) {
        // Get info for image files
        title = "Image";
        description = "Image file";
        additionalInfo = "File path: $path";
      } else {
        // For other file types
        additionalInfo =
            "File path: $path\nFile type: ${file.type}\nMIME type: ${file.mimeType}";
      }

      // Print all the gathered information
      print("\n=== REPOSTING $contentType CONTENT ===");
      print("Title: $title");
      print("Description: $description");
      print("Image URL: $imageUrl");
      if (additionalInfo.isNotEmpty) {
        print("Additional Info: $additionalInfo");
      }
      print("=================================\n");

      // Show appropriate success message
      if (success) {
        final newDescription =
            await rewriteContentWithAI(title, description, imageUrl);
        print("🔁 Rewritten Description: $newDescription");
        await shareLinkedInWithImageUrl(
          context: context,
          imageUrl: imageUrl,
          text: newDescription,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$contentType content reposted successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error reposting content"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Handle any unexpected errors
      print("\n=== REPOSTING ERROR ===");
      print("Error: $e");
      print("======================\n");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error reposting content: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
