import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/posts.dart';

/// Servicio principal que coordina la interacción entre agentes.
class SAPAIAssistantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ContextAgent _contextAgent = ContextAgent();
  final ResponseAgent _responseAgent = ResponseAgent();
  final ValidationAgent _validationAgent = ValidationAgent();

  // Contexto base (para temas generales) con directrices de estilo.
  String baseContext = '''
-You are an expert SAP professional assistant. 
-Your goal is to provide professional, concise, and accurate answers about SAP-related topics based on your comprehensive knowledge of SAP systems, modules, and best practices. 
-RESPOND IN PLAIN TEXT ONLY.
-Do not use markdown, code blocks, or special formatting.
-Avoid symbols like *, -, >, ```, etc.
''';

  /// Método principal para generar la respuesta de la IA.
  Future<(String, List<SAPPost>)> generateAIResponse({
    required String query,
    required String username,
  }) async {
    // 1. Siempre se buscan posts en la comunidad
    final (contextWithPosts, posts) = await _contextAgent.generateContext(
      query: query,
      baseContext: baseContext,
    );

    // 2. Analiza si se encontró alguno de valor (por ejemplo, contenido relevante)
    bool hasCommunityResponse =
        posts.isNotEmpty && posts.any((post) => post.content.trim().isNotEmpty);

    // 3. Define el contexto final:
    //    - Si se encontraron posts relevantes, se usa el contexto enriquecido.
    //    - Si no se encontraron, se usa el baseContext + consulta genérica.
    final String finalContext = hasCommunityResponse
        ? contextWithPosts
        : '''
You are an expert SAP professional assistant with comprehensive knowledge.
Query: "$query"
$baseContext
''';

    // 4. Se genera la respuesta (se pueden generar varias candidatas).
    List<String> candidates = await _responseAgent
        .generateCandidateResponses(finalContext, query, count: 1);

    // 5. Se evalúan y se selecciona la mejor respuesta.
    String bestResponse = _validationAgent.selectBestResponse(candidates);
    String feedback = _validationAgent.generateFeedback(bestResponse);

    // 6. Si el feedback es negativo, se refina la respuesta.
    if (feedback.contains('insuficiente')) {
      bestResponse =
          await _responseAgent.refineResponse(finalContext, query, feedback);
      // Se evalúa la respuesta refinada para asegurarse de su calidad.
      final double refinedScore =
          _validationAgent.evaluateResponse(bestResponse);
      if (refinedScore < 1.0) {
        bestResponse =
            'La respuesta no pudo ser refinada adecuadamente. Inténtalo de nuevo más tarde.';
      }
    }

    // 7. (Opcional) Guarda la interacción en Firestore.
    await _saveAIInteraction(
      username: username,
      query: query,
      response: bestResponse,
      hasCommunityResponse: hasCommunityResponse,
    );

    return (bestResponse, posts);
  }

  /// Guarda la interacción en Firestore.
  Future<void> _saveAIInteraction({
    required String username,
    required String query,
    required String response,
    required bool hasCommunityResponse,
  }) async {
    try {
      await _firestore.collection('ai_interactions').add({
        'username': username,
        'query': query,
        'response': response,
        'hasCommunityResponse': hasCommunityResponse,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving AI interaction: $e');
    }
  }
}


/// Agente encargado de generar el contexto basado en la comunidad y posts relevantes.
class ContextAgent {
  /// Siempre se busca en los posts de la comunidad.
  /// Si se encuentran posts, se incorpora su contenido en el contexto enriquecido.
  Future<(String, List<SAPPost>)> generateContext({
    required String query,
    required String baseContext,
  }) async {
    try {
      // Buscar posts en la comunidad
      List<SAPPost> relevantPosts = await _findRelevantPosts(query);
      final contextInsights = relevantPosts.isNotEmpty
          ? _extractContextInsights(relevantPosts)
          : "";

      // Se arma el contexto enriquecido, indicando si se usaron posts.
      final enhancedContext = relevantPosts.isNotEmpty
          ? '''
You are an expert SAP professional assistant with community-backed insights.

Community Context for Query "$query":
$contextInsights

Base Guidelines:
- Provide technical and business-oriented insights.
- Reference community knowledge when applicable.
- Use professional SAP terminology.
- Be precise and actionable.
- If information is limited, offer general guidance.
- $baseContext
'''
          : '''
You are an expert SAP professional assistant with comprehensive knowledge.

Query: "$query"

Base Guidelines:
- Provide technical and business-oriented insights.
- Use professional SAP terminology.
- Be precise and actionable.
- If information is limited, offer general guidance.
- $baseContext
''';

      return (enhancedContext, relevantPosts);
    } catch (e) {
      print('Error generating context: $e');
      return ("", <SAPPost>[]);
    }
  }

  Future<List<SAPPost>> _findRelevantPosts(String query) async {
    try {
      return await FirebaseService().getPostsByKeyword(query);
    } catch (e) {
      print('Error finding relevant posts: $e');
      return [];
    }
  }

  String _extractContextInsights(List<SAPPost> posts) {
    final buffer = StringBuffer();
    for (final post in posts.take(3)) {
      final snippet = post.content.length > 200
          ? post.content.substring(0, post.content.length - 50)
          : post.content;
      buffer.writeln('• $snippet [Source: ${post.author}]');
    }
    return buffer.toString();
  }
}

/// Agente encargado de generar respuestas utilizando la API DeepSeek.
class ResponseAgent {
  final String _apiKey = 'sk-dab16eb7cc2e4128850c712015edbfb3';
  final String _apiUrl = 'https://api.deepseek.com/chat/completions';

  /// Solicita [count] respuestas candidatas.
  Future<List<String>> generateCandidateResponses(String context, String query,
      {int count = 3}) async {
    List<String> candidates = [];
    for (int i = 0; i < count; i++) {
      final payload = {
        'model': 'deepseek-chat',
        'messages': [
          {'role': 'system', 'content': context},
          {'role': 'user', 'content': query}
        ],
        'stream': false
      };

      try {
        final response = await http.post(
          Uri.parse(_apiUrl),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json'
          },
          body: json.encode(payload),
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          final candidate = responseData['choices'][0]['message']['content'];
          candidates.add(candidate);
        } else {
          candidates.add('Error generating response.');
        }
      } catch (e) {
        print('Error generating candidate response: $e');
        candidates.add('Error processing request.');
      }
    }
    return candidates;
  }

  /// Genera una respuesta refinada basándose en el feedback.
  Future<String> refineResponse(
      String context, String query, String feedback) async {
    final refinedQuery =
        '$query\n\nFeedback: $feedback\n\nPlease refine your answer accordingly.';
    final payload = {
      'model': 'deepseek-chat',
      'messages': [
        {'role': 'system', 'content': context},
        {'role': 'user', 'content': refinedQuery}
      ],
      'stream': false
    };

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json'
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['choices'][0]['message']['content'];
      } else {
        return 'Error generating refined response.';
      }
    } catch (e) {
      print('Error generating refined response: $e');
      return 'Error processing refinement request.';
    }
  }
}

/// Agente encargado de evaluar respuestas y generar feedback.
class ValidationAgent {
  /// Evalúa la respuesta y retorna un puntaje basado en diversos criterios.
  double evaluateResponse(String response) {
    double score = 0.0;
    if (response.isNotEmpty && !response.contains("Error")) {
      score += 1.0;
    }
    // Evalúa longitud
    if (response.length < 100) score -= 0.5;
    if (response.length > 1000) score -= 0.3;
    // Evalúa contenido técnico (presencia de términos SAP relevantes)
    final List<String> techTerms = [
      'SAP',
      'ERP',
      'módulo',
      'transacción',
      'ABAP',
      'HANA',
      'S/4',
      'BW',
      'tabla',
      'MM',
      'SD',
      'FI',
      'CO',
      'HR'
    ];
    int termCount = 0;
    for (final term in techTerms) {
      if (response.toLowerCase().contains(term.toLowerCase())) {
        termCount++;
      }
    }
    score += (termCount / 5).clamp(0.0, 1.0);
    // Evalúa estructura (múltiples oraciones y claridad)
    if (response.contains('.') && response.split('.').length > 3) {
      score += 0.5;
    }
    return score;
  }

  /// Selecciona la mejor respuesta entre las candidatas.
  String selectBestResponse(List<String> responses) {
    double bestScore = double.negativeInfinity;
    String bestResponse = '';
    for (final response in responses) {
      double score = evaluateResponse(response);
      if (score > bestScore) {
        bestScore = score;
        bestResponse = response;
      }
    }
    return bestResponse;
  }

  /// Genera feedback basado en la evaluación de la respuesta.
  String generateFeedback(String response) {
    final score = evaluateResponse(response);
    if (score < 1.0) {
      return 'La respuesta es insuficiente. Agrega más detalles técnicos y asegúrate de que la información sea precisa y accionable.';
    } else if (score < 1.5) {
      return 'La respuesta es adecuada, pero podría incluir más terminología SAP específica y ejemplos prácticos.';
    } else {
      return 'La respuesta es adecuada.';
    }
  }
}
