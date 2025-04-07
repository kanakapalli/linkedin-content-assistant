import 'package:dart_openai/dart_openai.dart';

void initOpenAI() {
  OpenAI.apiKey = 'you open ai key here'; // Replace with your actual key
}

Future<String> rewriteContentWithAI(
    String title, String description, String imageUrl) async {
  try {
    final prompt = '''
Rewrite the following post description in a more engaging and creative way.
Title: $title
Description: $description
Image URL: $imageUrl
Only return the rewritten description.
''';

    final response = await OpenAI.instance.chat.create(
      model: "gpt-3.5-turbo",
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.system,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(
              "You are a creative social media assistant.",
            ),
          ],
        ),
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt),
          ],
        ),
      ],
    );

    // Safely access and return the response
    final reply = response.choices.first.message.content?.first.text;
    return reply?.trim() ?? "No response generated.";
  } catch (e) {
    print("OpenAI error: $e");
    return "Could not rewrite description.";
  }
}
