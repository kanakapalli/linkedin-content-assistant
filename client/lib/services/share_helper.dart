import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image/image.dart' as img;

/// Check if LinkedIn app is installed.
Future<bool> tryOpenLinkedIn() async {
  final Uri linkedInUri = Uri.parse('linkedin://');
  return await canLaunchUrl(linkedInUri);
}

/// Copy a file to a temporary path for sharing.
Future<String> getShareablePath(File file) async {
  final directory = await getTemporaryDirectory();
  final path = directory.path;
  final fileName = file.path.split('/').last;
  final newFile = await file.copy('$path/$fileName');
  return newFile.path;
}

/// Share image + text via LinkedIn (local file).
Future<void> shareLinkedInSpecific({
  required BuildContext context,
  required File? selectedImage,
  required String text,
}) async {
  try {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (selectedImage == null) {
      await shareTextOnly(context, text);
      return;
    }

    await Clipboard.setData(ClipboardData(text: text));
    final sharePath = await getShareablePath(selectedImage);
    final xFile = XFile(sharePath);

    final bool linkedInAvailable = await tryOpenLinkedIn();

    if (linkedInAvailable) {
      final result = await Share.shareXFiles(
        [xFile],
        text: "", // LinkedIn ignores it; user pastes manually
        subject: "",
      );

      if (result.status == ShareResultStatus.success) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
                'Image shared. Text copied to clipboard. Paste it in LinkedIn.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content: Text('LinkedIn not found. Using system share instead.')),
      );
      await shareViaSystemShare(context, selectedImage, text);
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error sharing to LinkedIn: $e')),
    );
  }
}

/// Share text and image using system share as fallback.
Future<void> shareViaSystemShare(
  BuildContext context,
  File? image,
  String text,
) async {
  try {
    if (image != null) {
      final sharePath = await getShareablePath(image);
      final xFile = XFile(sharePath);
      final result = await Share.shareXFiles(
        [xFile],
        text: "$text\n\n$text",
        subject: text,
      );

      if (result.status == ShareResultStatus.success) {
        await Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Content shared. Text copied to clipboard.')),
        );
      }
    } else {
      await shareTextOnly(context, text);
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error sharing via system: $e')),
    );
  }
}

/// Share text only, preferably via LinkedIn.
Future<void> shareTextOnly(BuildContext context, String text) async {
  try {
    final bool linkedInAvailable = await tryOpenLinkedIn();

    if (linkedInAvailable) {
      final Uri linkedInShare = Uri.parse('linkedin://');
      await launchUrl(linkedInShare);

      await Clipboard.setData(ClipboardData(text: text));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Text copied to clipboard. Paste in LinkedIn to complete your post.')),
      );
    } else {
      await Share.share(
        text,
        subject: 'LinkedIn Post',
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error sharing text: $e')),
    );
  }
}

/// Share to LinkedIn using an image from a URL.
Future<void> shareLinkedInWithImageUrl({
  required BuildContext context,
  required String imageUrl,
  required String text,
}) async {
  try {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Step 1: Download the image
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode != 200) {
      throw Exception("Failed to download image from URL");
    }

    // Step 2: Decode and re-encode the image to ensure it's valid
    final originalImage = img.decodeImage(response.bodyBytes);
    if (originalImage == null) throw Exception("Could not decode image");
    final reencodedBytes = img.encodeJpg(originalImage);

    // Step 3: Share from memory using XFile.fromData (IMPORTANT!)
    final xFile = XFile.fromData(
      reencodedBytes,
      name: "linkedin_image.jpg",
      mimeType: "image/jpeg",
    );

    // Copy the text to clipboard
    await Clipboard.setData(ClipboardData(text: text));

    // Try to open LinkedIn
    final linkedInAvailable = await canLaunchUrl(Uri.parse('linkedin://'));

    if (linkedInAvailable) {
      final result = await Share.shareXFiles(
        [xFile],
        text: "", // let user paste from clipboard
      );

      if (result.status == ShareResultStatus.success) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'Image shared. Text copied to clipboard. Paste it in LinkedIn.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('LinkedIn not found. Using system share instead.'),
        ),
      );

      await Share.shareXFiles(
        [xFile],
        text: "$text\n\n$text",
        subject: text,
      );

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Content shared. Text copied to clipboard.'),
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error sharing from image URL: $e')),
    );
  }
}
