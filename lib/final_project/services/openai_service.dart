import 'dart:convert';
import 'package:http/http.dart' as http;
import '../ai_model/message.dart';

class OpenAIService {
  static const String _backendBaseUrl = String.fromEnvironment(
    'OPENROUTER_BACKEND_URL',
    defaultValue:
        'https://us-central1-finance-app-9e679.cloudfunctions.net/api',
  );

  static const String _model = "nvidia/nemotron-3-nano-30b-a3b:free";
  static const String _imageModel = "blackforestlabs/flux-1.0-schnell:free";

  Uri _buildUri(String path) {
    final base = _backendBaseUrl.endsWith('/')
        ? _backendBaseUrl.substring(0, _backendBaseUrl.length - 1)
        : _backendBaseUrl;
    return Uri.parse('$base$path');
  }

  Future<String> sendMessage(List<Message> messages) async {
    try {
      final response = await http.post(
        _buildUri('/chat'),
        headers: {
          'Content-Type': 'application/json',
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
        final content = data['content'] ?? data['choices']?[0]?['message']?['content'];
        if (content is String && content.trim().isNotEmpty) {
          return content.trim();
        }
        throw Exception('Invalid response format from chat backend');
      } else {
        throw Exception('Chat backend error ${response.statusCode}: ${response.body}');
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
      final response = await http.post(
        _buildUri('/image'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _imageModel,
          'prompt': prompt,
          'num_images': 1,
        }),
      ).timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final url = data['url'] ?? data['data']?[0]?['url'];
        if (url is String && url.isNotEmpty) {
          return url;
        }
        throw Exception('Invalid response format from image backend');
      } else {
        throw Exception('Image backend error ${response.statusCode}: ${response.body}');
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
