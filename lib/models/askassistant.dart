import 'dart:convert';
import 'package:http/http.dart' as http;

class AssistantResponse {
  final String responseChat;
  final List<QueryMatch> matches;

  AssistantResponse({required this.responseChat, required this.matches});

  factory AssistantResponse.fromJson(Map<String, dynamic> json) {
    final matchesJson = json['response_query']['matches'] as List;
    final matches = matchesJson.map((m) => QueryMatch.fromJson(m)).toList();

    return AssistantResponse(
      responseChat: json['response_chat'],
      matches: matches,
    );
  }
}

class QueryMatch {
  final String id;
  final String text;
  final String? title;
  final String? module;
  final List<String>? tags;
  final double? score;

  QueryMatch({
    required this.id,
    required this.text,
    this.title,
    this.module,
    this.tags,
    this.score,
  });

  factory QueryMatch.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] ?? {};
    return QueryMatch(
      id: json['id'],
      text: metadata['text'] ?? '',
      title: metadata['title'],
      module: metadata['module'],
      tags: List<String>.from(metadata['tags'] ?? []),
      score: (json['score'] ?? 0).toDouble(),
    );
  }
}

class AskAssistantService {
  final String baseUrl;

  AskAssistantService({required this.baseUrl});

  Future<AssistantResponse> askQuestion(String question) async {
    final url = Uri.parse('$baseUrl/ask-assistant');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'question': question}),
    );

    if (response.statusCode == 200) {
      return AssistantResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error al preguntar al asistente: ${response.body}');
    }
  }
}
