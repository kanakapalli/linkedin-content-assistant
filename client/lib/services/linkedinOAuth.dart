// import 'dart:developer';

// import 'package:flutter/material.dart';
// import 'package:flutter_web_auth/flutter_web_auth.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class LinkedInAuth {
//   // Your LinkedIn app credentials
//   final String clientId = "86if8wmdafje36";
//   final String clientSecret = "WPL_AP1.kwB88Q8fEyUbTdMX.CBsEtA==";

//   // Use the HTTPS URL as LinkedIn requires
//   final String redirectUri = "https://orch.life/app";

//   Future<String?> authenticate() async {
//     try {
//       // Create the LinkedIn authorization URL with proper encoding
//       final String state = DateTime.now().millisecondsSinceEpoch.toString();
//       final String authUrl = "https://www.linkedin.com/oauth/v2/authorization"
//           "?response_type=code"
//           "&client_id=$clientId"
//           "&redirect_uri=${Uri.encodeComponent(redirectUri)}"
//           "&scope=openid%20profile%20email%20w_member_social"
//           "&state=$state";

//       print("LinkedIn auth URL: $authUrl");

//       // For flutter_web_auth, we need to specify what URL scheme to handle
//       // Since your redirect URL is https://orch.life/app, we use "https" as the scheme
//       final result = await FlutterWebAuth.authenticate(
//         url: authUrl,
//         callbackUrlScheme: "https",
//       );

//       print("Auth result: $result");

//       // Extract authorization code from the result
//       final code = Uri.parse(result).queryParameters['code'];
//       print("Received auth code: $code");

//       if (code != null) {
//         // Exchange the code for an access token
//         return await _getAccessToken(code);
//       }
//     } catch (e) {
//       print("LinkedIn auth error: $e");
//     }
//     return null;
//   }

//   Future<String?> _getAccessToken(String code) async {
//     try {
//       print("Exchanging code for access token...");

//       final response = await http.post(
//         Uri.parse("https://www.linkedin.com/oauth/v2/accessToken"),
//         headers: {"Content-Type": "application/x-www-form-urlencoded"},
//         body: {
//           "grant_type": "authorization_code",
//           "code": code,
//           "redirect_uri": redirectUri,
//           "client_id": clientId,
//           "client_secret": clientSecret,
//         },
//       );

//       print("Token response status: ${response.statusCode}");
//       print("Token response body: ${response.body}");

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         return data['access_token'];
//       } else {
//         print("Failed to get access token: ${response.reasonPhrase}");
//       }
//     } catch (e) {
//       print("Access token error: $e");
//     }
//     return null;
//   }

//   Future<Map<String, dynamic>?> getPost(String url, String accessToken) async {
//     try {
//       // Extract the post ID from the URL
//       final postId = _extractPostId(url);
//       if (postId == null) {
//         print("Could not extract post ID from URL: $url");
//         return null;
//       }

//       print("Fetching LinkedIn post with ID: $postId");

//       final response = await http.get(
//         Uri.parse("https://api.linkedin.com/v2/ugcPosts/$postId"),
//         headers: {
//           "Authorization": "Bearer $accessToken",
//           "X-Restli-Protocol-Version": "2.0.0",
//         },
//       );

//       print("Post API response status: ${response.statusCode}");

//       if (response.statusCode == 200) {
//         return jsonDecode(response.body);
//       } else {
//         print("Failed to get post: ${response.body}");
//       }
//     } catch (e) {
//       print("Get post error: $e");
//     }
//     return null;
//   }

//   String? _extractPostId(String url) {
//     // Extract the activity ID from the LinkedIn post URL
//     final activityRegex = RegExp(r'activity-(\d+)');
//     final match = activityRegex.firstMatch(url);

//     if (match != null && match.group(1) != null) {
//       return match.group(1);
//     }

//     // Alternative pattern
//     final alternativeRegex = RegExp(r'activity:(\d+)');
//     final altMatch = alternativeRegex.firstMatch(url);

//     if (altMatch != null && altMatch.group(1) != null) {
//       return altMatch.group(1);
//     }

//     return null;
//   }

//   Future<Map<String, dynamic>?> getPostData(String postUrl) async {
//     try {
//       final encodedUrl = Uri.encodeComponent(postUrl);
//       final oEmbedUrl =
//           'https://www.linkedin.com/posts/oembed?url=$encodedUrl&format=json';

//       print('Fetching LinkedIn post data from oEmbed: $oEmbedUrl');

//       final response = await http.get(Uri.parse(oEmbedUrl));

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         return data;
//       } else {
//         print('Failed to get LinkedIn post data: ${response.reasonPhrase}');
//         return null;
//       }
//     } catch (e) {
//       print('Error getting LinkedIn post data: $e');
//       return null;
//     }
//   }

//   /// Function to post content to LinkedIn (Text, Image(s), or Video)
//   Future<Map<String, dynamic>?> postLinkedInContent({
//     required String caption,
//     List<String>? imageUrls,
//     String? videoUrl,
//     required String accessToken,
//   }) async {
//     try {
//       List<Map<String, dynamic>> mediaList = [];
//       String linkedInMemberId =
//           await getLinkedInMemberId(accessToken); // Fetch member ID
//       print("Fetched LinkedIn Member ID: $linkedInMemberId");

//       // Upload images if provided
//       if (imageUrls != null && imageUrls.isNotEmpty) {
//         for (String imageUrl in imageUrls) {
//           print("Uploading image: $imageUrl");
//           final asset = await _uploadImageToLinkedIn(
//               accessToken, imageUrl, linkedInMemberId);
//           if (asset != null) {
//             print("Image uploaded successfully: $asset");
//             mediaList.add({
//               "status": "READY",
//               "media": {
//                 "media": asset,
//                 "title": {"text": "Uploaded Image"}
//               }
//             });
//           } else {
//             print("Failed to upload image: $imageUrl");
//           }
//         }
//       }

//       // Upload video if provided
//       if (videoUrl != null && videoUrl.isNotEmpty) {
//         print("Uploading video: $videoUrl");
//         final asset = await _uploadVideoToLinkedIn(
//             accessToken, videoUrl, linkedInMemberId);
//         if (asset != null) {
//           print("Video uploaded successfully: $asset");
//           mediaList.add({
//             "status": "READY",
//             "media": {
//               "media": asset,
//               "title": {"text": "Uploaded Video"}
//             }
//           });
//         } else {
//           print("Failed to upload video: $videoUrl");
//         }
//       }

//       // Determine media category
//       String shareMediaCategory = "NONE";
//       if (mediaList.isNotEmpty) {
//         if (videoUrl != null && videoUrl.isNotEmpty) {
//           shareMediaCategory = "VIDEO";
//         } else {
//           shareMediaCategory = "IMAGE";
//         }
//       }

//       // Define the post body
//       Map<String, dynamic> postBody = {
//         "author": "urn:li:person:$linkedInMemberId",
//         "lifecycleState": "PUBLISHED",
//         "specificContent": {
//           "com.linkedin.ugc.ShareContent": {
//             "shareCommentary": {"text": caption},
//             "shareMediaCategory": shareMediaCategory,
//             if (mediaList.isNotEmpty) "media": mediaList,
//           }
//         },
//         "visibility": {"com.linkedin.ugc.MemberNetworkVisibility": "PUBLIC"}
//       };

//       print("Post body: ${jsonEncode(postBody)}");

//       // Make the API request to post the content
//       final postResponse = await http.post(
//         Uri.parse("https://api.linkedin.com/v2/ugcPosts"),
//         headers: {
//           "Authorization": "Bearer $accessToken",
//           "Content-Type": "application/json",
//           "X-Restli-Protocol-Version": "2.0.0",
//         },
//         body: jsonEncode(postBody),
//       );

//       // Handle the response
//       if (postResponse.statusCode == 201 || postResponse.statusCode == 200) {
//         print("Post published successfully!");
//         return jsonDecode(postResponse.body);
//       } else {
//         print("Failed to publish post: ${postResponse.body}");
//         return jsonDecode(postResponse.body);
//       }
//     } catch (e) {
//       print("Error posting content to LinkedIn: $e");
//     }
//     return null;
//   }

//   /// Fetch LinkedIn Member ID
//   Future<String> getLinkedInMemberId(String accessToken) async {
//     final response = await http.get(
//       Uri.parse(
//           "https://api.linkedin.com/v2/me?projection=(id,firstName,lastName)"),
//       headers: {
//         "Authorization": "Bearer $accessToken",
//         "Content-Type": "application/json",
//         "X-Restli-Protocol-Version": "2.0.0",
//       },
//     );

//     print("Response: ${response.body}");

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       print("LinkedIn Member ID: ${data['id']}");
//       return data["id"];
//     } else {
//       print("Failed to fetch LinkedIn Member ID: ${response.body}");
//       throw Exception("Failed to fetch LinkedIn Member ID: ${response.body}");
//     }
//   }

//   /// Upload an image to LinkedIn and return its asset URN
//   Future<String?> _uploadImageToLinkedIn(
//       String accessToken, String imageUrl, String memberId) async {
//     try {
//       final registerUploadResponse = await http.post(
//         Uri.parse("https://api.linkedin.com/v2/assets?action=registerUpload"),
//         headers: {
//           "Authorization": "Bearer $accessToken",
//           "Content-Type": "application/json",
//           "X-Restli-Protocol-Version": "2.0.0",
//         },
//         body: jsonEncode({
//           "registerUploadRequest": {
//             "recipes": ["urn:li:digitalmediaRecipe:feedshare-image"],
//             "owner": "urn:li:member:$memberId",
//             "serviceRelationships": [
//               {
//                 "relationshipType": "OWNER",
//                 "identifier": "urn:li:userGeneratedContent"
//               }
//             ]
//           }
//         }),
//       );

//       if (registerUploadResponse.statusCode != 200) {
//         print(
//             "Failed to register image upload: ${registerUploadResponse.body}");
//         return null;
//       }

//       final registerResponse = jsonDecode(registerUploadResponse.body);
//       final asset = registerResponse["value"]["asset"];
//       final uploadUrl = registerResponse["value"]["uploadMechanism"]
//               ["com.linkedin.digitalmedia.uploading.MediaUploadHttpRequest"]
//           ["uploadUrl"];

//       final imageBytes = await http.get(Uri.parse(imageUrl));
//       final uploadResponse = await http.put(
//         Uri.parse(uploadUrl),
//         headers: {
//           "Authorization": "Bearer $accessToken",
//           "Content-Type": "image/jpeg"
//         },
//         body: imageBytes.bodyBytes,
//       );

//       if (uploadResponse.statusCode != 201) {
//         print("Image upload failed: ${uploadResponse.body}");
//         return null;
//       }

//       return asset;
//     } catch (e) {
//       print("Error uploading image to LinkedIn: $e");
//       return null;
//     }
//   }

//   /// Upload a video to LinkedIn and return its asset URN
//   Future<String?> _uploadVideoToLinkedIn(
//       String accessToken, String videoUrl, String memberId) async {
//     try {
//       final registerUploadResponse = await http.post(
//         Uri.parse("https://api.linkedin.com/v2/assets?action=registerUpload"),
//         headers: {
//           "Authorization": "Bearer $accessToken",
//           "Content-Type": "application/json",
//           "X-Restli-Protocol-Version": "2.0.0",
//         },
//         body: jsonEncode({
//           "registerUploadRequest": {
//             "recipes": ["urn:li:digitalmediaRecipe:feedshare-video"],
//             "owner": "urn:li:member:$memberId",
//             "serviceRelationships": [
//               {
//                 "relationshipType": "OWNER",
//                 "identifier": "urn:li:userGeneratedContent"
//               }
//             ]
//           }
//         }),
//       );

//       if (registerUploadResponse.statusCode != 200) {
//         print(
//             "Failed to register video upload: ${registerUploadResponse.body}");
//         return null;
//       }

//       final registerResponse = jsonDecode(registerUploadResponse.body);
//       final asset = registerResponse["value"]["asset"];
//       final uploadUrl = registerResponse["value"]["uploadMechanism"]
//               ["com.linkedin.digitalmedia.uploading.MediaUploadHttpRequest"]
//           ["uploadUrl"];

//       final videoBytes = await http.get(Uri.parse(videoUrl));
//       final uploadResponse = await http.put(
//         Uri.parse(uploadUrl),
//         headers: {
//           "Authorization": "Bearer $accessToken",
//           "Content-Type": "video/mp4"
//         },
//         body: videoBytes.bodyBytes,
//       );

//       if (uploadResponse.statusCode != 201) {
//         print("Video upload failed: ${uploadResponse.body}");
//         return null;
//       }

//       return asset;
//     } catch (e) {
//       print("Error uploading video to LinkedIn: $e");
//       return null;
//     }
//   }
// }
