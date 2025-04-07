import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:receive_sharing_intent_example/services/openAi.dart';

class CommentGeneratorScreen extends StatefulWidget {
  final String? title;
  final String? description;
  final String? imageUrl;

  const CommentGeneratorScreen({
    Key? key,
    this.title,
    this.description,
    this.imageUrl,
  }) : super(key: key);

  @override
  _CommentGeneratorScreenState createState() => _CommentGeneratorScreenState();
}

class _CommentGeneratorScreenState extends State<CommentGeneratorScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  List<String> _comments = [];
  String _error = '';
  bool _hasContentToProcess = false;

  @override
  void initState() {
    super.initState();
    // Check if we have enough content to generate default comments
    _hasContentToProcess = widget.title?.isNotEmpty == true ||
        widget.description?.isNotEmpty == true;

    // Only generate default comments if we have content
    if (_hasContentToProcess) {
      _generateDefaultComments();
    }
  }

  Future<void> _generateDefaultComments() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final title = widget.title?.isNotEmpty == true
          ? widget.title!
          : "No title provided";
      final description = widget.description?.isNotEmpty == true
          ? widget.description!
          : "No description provided";

      final content =
          "Generate 10 unique, engaging comments for the following LinkedIn post. "
          "Make each comment different in tone and focus. Keep them professional, relevant, and around "
          "2-4 sentences each. Separate comments with '|COMMENT|' so I can parse them easily."
          "\n\nPost Title: $title"
          "\nPost Description: $description"
          "${widget.imageUrl != null ? "\nPost has an image: Yes" : "\nPost has an image: No"}";

      final result =
          await rewriteContentWithAI(title, content, widget.imageUrl ?? "");

      // Parse comments from the response
      final comments = result
          .split('|COMMENT|')
          .where((comment) => comment.trim().isNotEmpty)
          .toList();

      setState(() {
        _comments = comments.length > 10 ? comments.sublist(0, 10) : comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error generating comments: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _generateCommentsWithPrompt() async {
    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a prompt')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final title = widget.title?.isNotEmpty == true
          ? widget.title!
          : "No title provided";
      final description = widget.description?.isNotEmpty == true
          ? widget.description!
          : "No description provided";

      String content;
      if (_hasContentToProcess) {
        content =
            "Generate 10 unique, engaging comments for the following LinkedIn post based on "
            "this specific instruction: ${_promptController.text}\n\n"
            "Make each comment different in tone and focus, following the given instruction. "
            "Keep them professional and around 2-4 sentences each. "
            "Separate comments with '|COMMENT|' so I can parse them easily."
            "\n\nPost Title: $title"
            "\nPost Description: $description"
            "${widget.imageUrl != null ? "\nPost has an image: Yes" : "\nPost has an image: No"}";
      } else {
        // If no content provided, just use the prompt directly
        content =
            "Generate 10 unique, engaging comments based on this prompt: ${_promptController.text}.\n\n"
            "Make each comment different in tone and focus. Keep them professional and around "
            "2-4 sentences each. Separate comments with '|COMMENT|' so I can parse them easily.";
      }

      final result = await rewriteContentWithAI(
          _hasContentToProcess ? title : "Comment Suggestions",
          content,
          widget.imageUrl ?? "");

      // Parse comments from the response
      final comments = result
          .split('|COMMENT|')
          .where((comment) => comment.trim().isNotEmpty)
          .toList();

      setState(() {
        _comments = comments.length > 10 ? comments.sublist(0, 10) : comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error generating comments: $e';
        _isLoading = false;
      });
    }
  }

  void _copyComment(String comment) {
    Clipboard.setData(ClipboardData(text: comment));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Comment copied to clipboard')),
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comment Generator'),
        actions: [
          if (_hasContentToProcess)
            IconButton(
              icon: Icon(Icons.refresh),
              tooltip: 'Generate New Comments',
              onPressed: _generateDefaultComments,
            ),
        ],
      ),
      body: Column(
        children: [
          // Post information preview (only if we have content)
          if (_hasContentToProcess)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              color: Colors.grey.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Generating comments for:',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  if (widget.title?.isNotEmpty == true)
                    Text(
                      widget.title!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (widget.title?.isNotEmpty == true) SizedBox(height: 4),
                  if (widget.description?.isNotEmpty == true)
                    Text(
                      widget.description!,
                      style: TextStyle(fontSize: 14),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              color: Colors.purple.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.purple.shade800),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Write your comment prompt below to get suggestions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.purple.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Examples: "Write a supportive comment about career growth" or "Create an insightful comment about leadership"',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ],
              ),
            ),

          // Prompt input
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _promptController,
                  decoration: InputDecoration(
                    hintText: _hasContentToProcess
                        ? 'Enter specific instructions for comment generation...'
                        : 'Describe what kind of comment you need...',
                    labelText: _hasContentToProcess
                        ? 'Custom Prompt (Optional)'
                        : 'What do you want to comment about?',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.edit),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _generateCommentsWithPrompt,
                  icon: Icon(Icons.psychology),
                  label: Text(_hasContentToProcess
                      ? 'Generate With Prompt'
                      : 'Generate Suggestions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),

          // Comments list
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Generating engaging comments...'),
                      ],
                    ),
                  )
                : _error.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 48, color: Colors.red),
                              SizedBox(height: 16),
                              Text(_error),
                              SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _hasContentToProcess
                                    ? _generateDefaultComments
                                    : _generateCommentsWithPrompt,
                                child: Text('Try Again'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _comments.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.comment_outlined,
                                      size: 72, color: Colors.grey.shade400),
                                  SizedBox(height: 16),
                                  Text(
                                    _hasContentToProcess
                                        ? 'Ready to generate comments'
                                        : 'Enter a prompt to get comment suggestions',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade700),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    _hasContentToProcess
                                        ? 'Click the refresh button or use a custom prompt'
                                        : 'Describe what you want to comment about and click Generate',
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.all(16),
                            itemCount: _comments.length,
                            itemBuilder: (context, index) {
                              return _buildCommentCard(
                                  index + 1, _comments[index]);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(int index, String comment) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Comment number badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade800,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),

                // Comment text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment,
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Copy button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _copyComment(comment),
                icon: Icon(Icons.copy, size: 16),
                label: Text('Copy'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.deepPurple,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
