import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:receive_sharing_intent_example/services/share_helper.dart';

class LinkedInShareScreen extends StatefulWidget {
  @override
  _LinkedInShareScreenState createState() => _LinkedInShareScreenState();
}

class _LinkedInShareScreenState extends State<LinkedInShareScreen> {
  final TextEditingController _textController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _showSharingOptions() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Share to LinkedIn'),
          content: Text('Choose a sharing method:'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                shareTextOnly(context, _textController.text);
              },
              child: Text('Text Only (More Reliable)'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                shareLinkedInSpecific(
                  context: context,
                  selectedImage: _selectedImage,
                  text: _textController.text,
                );
              },
              child: Text('LinkedIn Image + Text'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareToLinkedIn() async {
    if (_textController.text.isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add text or select an image to share')),
      );
      return;
    }

    _showSharingOptions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LinkedIn Share'),
        backgroundColor: Color(0xFF0077B5),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'What do you want to share?',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            SizedBox(height: 20),
            if (_selectedImage != null) ...[
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                    height: 200,
                  ),
                ),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                  });
                },
                child: Text('Remove Image'),
              ),
              SizedBox(height: 10),
            ],
            if (_selectedImage == null)
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.image),
                label: Text('Add Image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                ),
              ),
            Spacer(),
            ElevatedButton.icon(
              onPressed: _shareToLinkedIn,
              icon: Icon(Icons.share),
              label: Text('Share to LinkedIn'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0077B5),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
