import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class ApiService {
  final String baseUrl;

  ApiService(
      {this.baseUrl =
          'https://beloved-selected-krill.ngrok-free.app'}); // Change to your actual API endpoint

  // Method to send shared files to your API
  Future<Map<String, dynamic>> sendSharedData(
      List<SharedMediaFile> sharedFiles) async {
    try {
      // Create a list of file data to send
      final List<Map<String, dynamic>> filesData = sharedFiles.map((file) {
        return {
          'path': file.path,
          'type': file.type.toString(),
          'mimeType': file.mimeType,
          'thumbnail': file.thumbnail,
          'duration': file.duration,
        };
      }).toList();

      // Prepare the request body
      final Map<String, dynamic> requestBody = {
        'sharedFiles': filesData,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Send the POST request
      final response = await http.post(
        Uri.parse('$baseUrl/shared-content'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer YOUR_API_KEY', // Replace with your actual API key
        },
        body: jsonEncode(requestBody),
      );

      // Check if the request was successful
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'error': 'Server returned status code ${response.statusCode}',
          'message': response.body,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Method to upload a file to your server
  Future<Map<String, dynamic>> uploadFile(String filePath) async {
    try {
      // Create a multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload'),
      );

      // Add file to the request
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      // Add headers
      request.headers.addAll({
        'Authorization':
            'Bearer YOUR_API_KEY', // Replace with your actual API key
      });

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // Check if the request was successful
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'error': 'Server returned status code ${response.statusCode}',
          'message': response.body,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Method to send URL metadata to your API
  Future<Map<String, dynamic>> sendUrlMetadata(
      Map<String, String> metadata) async {
    try {
      // Prepare the request body
      final Map<String, dynamic> requestBody = {
        'metadata': metadata,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Send the POST request
      final response = await http.post(
        Uri.parse('$baseUrl/url-metadata'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer YOUR_API_KEY', // Replace with your actual API key
        },
        body: jsonEncode(requestBody),
      );

      // Check if the request was successful
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'error': 'Server returned status code ${response.statusCode}',
          'message': response.body,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Method to get video download URL from a LinkedIn post URL
  Future<Map<String, dynamic>> getVideoDownloadUrl(String postUrl,
      {String? email, String? password}) async {
    try {
      // Prepare the request body
      final Map<String, dynamic> requestBody = {
        'url': postUrl,
        'email': email,
        'password': password,
      };

      // Send the POST request
      final response = await http.post(
        Uri.parse('$baseUrl/video-download-url'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      // Check if the request was successful
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'error': 'Server returned status code ${response.statusCode}',
          'message': response.body,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
