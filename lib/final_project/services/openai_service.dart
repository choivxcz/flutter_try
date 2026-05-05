import 'dart:convert';
import 'package:http/http.dart' as http;
import '../ai_model/message.dart';

class OpenAIService {
  static const String _endpoint =
      'https://openrouter.ai/api/v1/chat/completions';

  static const String _apiKey = String.fromEnvironment('OPENROUTER_API_KEY');

  static const String _model = "nvidia/nemotron-3-nano-30b-a3b:free";
  static const String _imageModel = "blackforestlabs/flux-1.0-schnell:free";

  Future<String> sendMessage(List<Message> messages) async {
    try {
      if (_apiKey.isEmpty) {
        throw Exception('Missing OpenRouter API key. Pass it with --dart-define=OPENROUTER_API_KEY=...');
      }

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://localhost',
          'X-Title': 'Choi AI App',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages
              .where((m) => m.role != 'system' || m == messages.first)
              .map((m) => {
                    'role': m.role,
                    'content': m.content,
                  })
              .toList(),
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key. Please check your OpenRouter API key.');
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please wait a moment and try again.');
      } else if (response.statusCode == 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception('OpenRouter Error ${response.statusCode}: ${response.body}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}. Please check your internet connection.');
    } catch (e) {
      if (e.toString().contains('SocketException') || 
          e.toString().contains('HandshakeException')) {
        throw Exception('Connection failed. Please check your internet connection.');
      }
      rethrow;
    }
  }

  Future<String> generateImage(String prompt) async {
    try {
      if (_apiKey.isEmpty) {
        throw Exception('Missing OpenRouter API key. Pass it with --dart-define=OPENROUTER_API_KEY=...');
      }

      final imageEndpoint = 'https://openrouter.ai/api/v1/images/generations';
      
      final response = await http.post(
        Uri.parse(imageEndpoint),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://localhost',
          'X-Title': 'Choi AI App',
        },
        body: jsonEncode({
          'model': _imageModel,
          'prompt': prompt,
          'num_images': 1,
        }),
      ).timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Handle different response formats
        if (data['data'] != null && data['data'].isNotEmpty) {
          return data['data'][0]['url'];
        }
        throw Exception('Invalid response format from image generation API');
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key. Please check your OpenRouter API key.');
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please wait a moment and try again.');
      } else if (response.statusCode == 404) {
        throw Exception('Image generation endpoint not found. Please check API configuration.');
      } else {
        throw Exception('Image generation failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to generate image: $e');
    }
  }

  Stream<String> streamMessage(List<Message> messages) async* {
    final response = await sendMessage(messages);
    yield response;
  }
}
