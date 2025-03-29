import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sapers/models/firebase_service.dart';
import 'dart:convert';
import 'package:sapers/models/posts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
class SAPAIAssistantService {
  final String _openAIApiKey = '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';
//dotenv.env['OPENAI'] ?? 'default_api_key';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> _generateEnhancedContext(String query) async {
    try {
      // Get relevant posts based on the query
      final relevantPosts = await _findRelevantPosts(query);

      // Extract key insights from relevant posts
      final contextInsights = _extractContextInsights(relevantPosts);

      // Combine base context with community insights
      return '''
      You are an expert SAP professional assistant with community-backed insights.

      Community Context for Query "$query":
      ${contextInsights.isNotEmpty ? contextInsights : "No specific community insights found."}

      Base Guidelines:
      - Provide technical and business-oriented insights
      - Reference community knowledge when applicable
      - Use professional SAP terminology
      - Be precise and actionable
      - If information is limited, offer general guidance
      ''';
    } catch (e) {
      print('Error generating enhanced context: $e');
      return _baseContext; // Fallback to base context
    }
  }

  // Find relevant posts based on query
  Future<List<SAPPost>> _findRelevantPosts(String query) async {
    try {
      // Use existing search method from FirebaseService
      final keywordPosts = await FirebaseService().getPostsByKeyword(query);

      // Optional: Add tag-based search for more comprehensive results
      final tags = await _extractRelevantTags(query);
      final tagPosts = await Future.wait(
          tags.map((tag) => FirebaseService().getPostsbyTag(tag)));

      // Combine and deduplicate posts
      final allPosts = [...keywordPosts, ...tagPosts.expand((list) => list)];
      return allPosts.toSet().toList();
    } catch (e) {
      print('Error finding relevant posts: $e');
      return [];
    }
  }

  // Extract relevant tags from query
  Future<List<String>> _extractRelevantTags(String query) async {
    try {
      // Get top tags and filter based on query similarity
      final topTags = await FirebaseService().getAllTags(10);
      return topTags
          .where((tag) => query.toLowerCase().contains(tag.toLowerCase()))
          .toList();
    } catch (e) {
      print('Error extracting tags: $e');
      return [];
    }
  }

  // Extract key insights from posts
  String _extractContextInsights(List<SAPPost> posts) {
    if (posts.isEmpty) return '';

    // Aggregate insights from top posts
    final insights = posts.take(3).map((post) {
      return '- ${post.author} shared: ${_truncateText(post.content, 100)}';
    }).join('\n');

    return '''
    Recent Community Insights:
    $insights
    ''';
  }

  // Truncate text to specified length
  String _truncateText(String text, int maxLength) {
    return text.length > maxLength
        ? '${text.substring(0, maxLength)}...'
        : text;
  }

  // Existing base context
  final String _baseContext = '''
  You are an expert SAP professional assistant. 
  Your goal is to provide professional, concise, and accurate answers 
  about SAP-related topics based on the available posts and your comprehensive 
  knowledge of SAP systems, modules, and best practices.
  ''';
  // Método principal para generar respuesta de IA con nueva estructura de API
  Future<String> generateAIResponse({
    required String query,
    required String username,
  }) async {
    try {
      // Preparar payload para nueva estructura de API de OpenAI
      final enhancedContext = await _generateEnhancedContext(query);

      final payload = {
        'model': 'o3-mini-2025-01-31',
        'input': [
          {
            'role': 'developer',
            'content': [
              {'type': 'input_text', 'text': enhancedContext}
            ]
          },
          {
            'role': 'user',
            'content': [
              {'type': 'input_text', 'text': query}
            ]
          }
        ],
        'text': {
          'format': {'type': 'text'}
        },
        'reasoning': {'effort': 'low'},
        'tools': [],
        'store': true
      };

      // Realizar llamada a OpenAI
      final response = await http.post(
          Uri.parse('https://api.openai.com/v1/responses'),
          headers: {
            'Authorization': 'Bearer $_openAIApiKey',
            'Content-Type': 'application/json'
          },
          body: json.encode(payload));

      // Procesar respuesta
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Extraer la respuesta del asistente de la nueva estructura
        final aiResponse = responseData['output'][1]['content'][0]['text'];

        // Opcionalmente, guardar interacción en Firestore
        //  await _saveAIInteraction(
        //     username: username, query: query, response: aiResponse);

        return aiResponse;
      } else {
        return 'Lo siento, no pude generar una respuesta en este momento.';
      }
    } catch (e) {
      print('Error in AI assistant: $e');
      return 'Ocurrió un error al procesar tu solicitud.';
    }
  }

  // Método para guardar interacciones de IA (sin cambios)
  Future<void> _saveAIInteraction({
    required String username,
    required String query,
    required String response,
  }) async {
    try {
      await _firestore.collection('ai_interactions').add({
        'username': username,
        'query': query,
        'response': response,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving AI interaction: $e');
    }
  }

  // Método para obtener historial de interacciones de IA (sin cambios)
  Stream<QuerySnapshot> getAIInteractionHistory(String username) {
    return _firestore
        .collection('ai_interactions')
        .where('username', isEqualTo: username)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
