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

  // Contexto base mejorado con enfoque de consultoría
  String baseContext = '''
You are an expert SAP professional assistant recognized as one of the best consultants globally. 
Your responses must be:
- Highly focused on the user's specific query
- Technically precise with clear, actionable advice
- Structured logically (e.g., "Explanation:", "Recommendation:", "Next Steps:" when applicable)
- Incorporate SAP best practices and real-world implementation experience
- Prioritize solutions that balance technical feasibility with business impact
- Acknowledge when additional information is needed for precise guidance
- For non-technical queries, respond appropriately without technical content
- RESPOND IN PLAIN TEXT ONLY. Avoid all formatting, symbols, and markdown
''';

  /// Método principal para generar la respuesta de la IA.
  Future<(String, List<SAPPost>)> generateAIResponse({
    required String query,
    required String username,
  }) async {
    // 1. Detectar si es un saludo primero
    if (_contextAgent._isGreeting(query)) {
      return (
        "¡Buenos días! ¿En qué puedo asistirte con SAP hoy?",
        <SAPPost>[]
      );
    }

    // 2. Buscar posts solo si es una consulta técnica
    final (contextWithPosts, posts) = await _contextAgent.generateContext(
      query: query,
      baseContext: baseContext,
    );

    // 3. Determinar si hay respuestas comunitarias relevantes
    bool hasCommunityResponse = posts.isNotEmpty &&
        posts.any((post) => _contextAgent._isTechnicallyRelevant(post, query));

    // 4. Construir contexto final
    final String finalContext = hasCommunityResponse
        ? contextWithPosts
        : '''
$baseContext

Query: "$query"
- Provide expert-level SAP guidance
- Include implementation considerations
- Highlight potential risks if applicable
''';

    // 5. Generar y validar respuesta
    List<String> candidates = await _responseAgent
        .generateCandidateResponses(finalContext, query, count: 3);

    String bestResponse = _validationAgent.selectBestResponse(candidates);
    bestResponse = _applyConsultantStyle(bestResponse);

    // 6. Refinar si es necesario
    if (_validationAgent
        .generateFeedback(bestResponse)
        .contains('insuficiente')) {
      bestResponse =
          await _responseAgent.refineResponse(finalContext, query, '''
Improve by:
1. Adding specific transaction codes
2. Referencing SAP notes if applicable
3. Providing configuration paths
4. Including business process context
''');
    }

    await _saveAIInteraction(
      username: username,
      query: query,
      response: bestResponse,
      hasCommunityResponse: hasCommunityResponse,
    );

    return (bestResponse, posts);
  }

  String _applyConsultantStyle(String response) {
    // Asegurar estructura profesional
    return response
        .replaceAll(RegExp(r'\n\s*'), '\n')
        .replaceAll('•', '') // Eliminar viñetas
        .replaceAll(RegExp(r'\*\*'), '') // Eliminar negritas
        .replaceAllMapped(
            RegExp(r'(?<=\. )\w'), (match) => match.group(0)!.toUpperCase())
        .replaceAll('Explanation:', 'Análisis:')
        .replaceAll('Recommendation:', 'Recomendación profesional:')
        .replaceAll('Next Steps:', 'Próximos pasos:');
  }

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
        'technical_depth': _validationAgent.evaluateResponse(response),
        'hasCommunityResponse': hasCommunityResponse,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving AI interaction: $e');
    }
  }
}

class ContextAgent {
  final List<String> _sapModules = [
    'FI',
    'CO',
    'MM',
    'SD',
    'PP',
    'QM',
    'PM',
    'PS',
    'WM',
    'HR',
    'SAP HANA',
    'ABAP',
    'Fiori',
    'BTP',
    'SuccessFactors',
    'Ariba'
  ];

  bool _isGreeting(String query) {
    final greetings = [
      'hola',
      'hola!',
      'buenos días',
      'buenas tardes',
      'buenas noches',
      'saludos',
      'adiós',
      'gracias'
    ];
    return greetings.contains(query.toLowerCase());
  }

  bool _isTechnicalTerm(String query) {
    return _sapModules.contains(query.toUpperCase()) ||
        query.length > 3 && query.contains(RegExp(r'[A-Z]{3}'));
  }

  bool _isTechnicallyRelevant(SAPPost post, String query) {
    return post.content.toLowerCase().contains(query.toLowerCase()) &&
        post.content.length > 100 &&
        _sapModules.any((module) => post.content.contains(module));
  }

  Future<(String, List<SAPPost>)> generateContext({
    required String query,
    required String baseContext,
  }) async {
    if (_isGreeting(query) ||
        (query.split(' ').length == 1 && !_isTechnicalTerm(query))) {
      return (baseContext, <SAPPost>[]);
    }

    List<SAPPost> relevantPosts = await _findRelevantPosts(query);
    // relevantPosts = relevantPosts
    //     .where((post) => _isTechnicallyRelevant(post, query))
    //     .toList();

    // final contextInsights = relevantPosts.isNotEmpty
    //     ? _extractContextInsights(relevantPosts, query)
    //     : "";

    final enhancedContext = relevantPosts.isNotEmpty
        ? '''
$baseContext

Directrices adicionales:
- Combinar conocimiento experto con ejemplos prácticos
- Priorizar soluciones validadas en implementaciones reales
- Mencionar consideraciones de actualización SAP cuando aplique
'''
        : baseContext;

    return (enhancedContext, relevantPosts);
  }

  Future<List<SAPPost>> _findRelevantPosts(String query) async {
    try {
      return await FirebaseService().getPostsByKeywordAI(query);
    } catch (e) {
      print('Error finding relevant posts: $e');
      return [];
    }
  }

  String _extractContextInsights(List<SAPPost> posts, String query) {
    final buffer = StringBuffer();
    for (final post in posts.take(2)) {
      final technicalContent = post.content
          .split(' ')
          .where((word) => _sapModules.contains(word.toUpperCase()))
          .join(', ');

      buffer.writeln('Experiencia reportada (${post.author}): '
          '${post.content.substring(0, 150)}... '
          'Elementos técnicos: ${technicalContent.isNotEmpty ? technicalContent : 'N/A'}');
    }
    return buffer.toString();
  }
}

class ResponseAgent {
  final String _apiKey = 'sk-dab16eb7cc2e4128850c712015edbfb3';
  final String _apiUrl = 'https://api.deepseek.com/chat/completions';

  Future<List<String>> generateCandidateResponses(String context, String query,
      {int count = 3}) async {
    List<String> candidates = [];

    final professionalPrompt = '''
Genera ${count} variaciones de respuesta profesional SAP considerando:
1. Nivel de detalle técnico apropiado
2. Mejores prácticas de implementación
3. Posibles integraciones con otros módulos
4. Consideraciones de performance''';

    for (int i = 0; i < count; i++) {
      final payload = {
        'model': 'deepseek-chat',
        'messages': [
          {'role': 'system', 'content': context},
          {'role': 'user', 'content': '$query\n$professionalPrompt'}
        ],
        'temperature': 0.7,
        'max_tokens': 350,
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
          final parsed =
              await compute(parseResponseInBackground, response.bodyBytes);

          //final decodedBody = utf8.decode(response.bodyBytes);
          candidates.add(parsed['choices'][0]['message']['content']);
        }
      } catch (e) {
        print('Error generating response: $e');
      }
    }
    return candidates;
  }

  static Map<String, dynamic> parseResponseInBackground(List<int> data) {
    return json.decode(utf8.decode(data));
  }

  Future<String> refineResponse(
      String context, String query, String feedback) async {
    final payload = {
      'model': 'deepseek-chat',
      'messages': [
        {'role': 'system', 'content': context},
        {'role': 'user', 'content': query},
        {'role': 'assistant', 'content': feedback}
      ],
      'temperature': 0.5,
      'max_tokens': 400,
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

      final parsed =
          await compute(parseResponseInBackground, response.bodyBytes);

      return parsed['choices'][0]['message']['content'];
    } catch (e) {
      return 'Error procesando la solicitud. Por favor intenta reformular tu pregunta.';
    }
  }
}

class ValidationAgent {
  final List<String> _technicalIndicators = [
    'transacción',
    'nota SAP',
    'SPRO',
    'tipo de dato',
    'RFC',
    'IDOC',
    'BAPI',
    'enhancement',
    'customizing',
    'debugging',
    'performance',
    'actualización',
    'migración',
    'Best Practice'
  ];

  double evaluateResponse(String response) {
    double score = 0.0;

    // Evaluación técnica
    final technicalDepth =
        _technicalIndicators.where((term) => response.contains(term)).length /
            5;
    score += technicalDepth.clamp(0.0, 2.0);

    // Estructura profesional
    if (response.contains('Análisis:') ||
        response.contains('Recomendación profesional:')) score += 1.0;

    // Accionabilidad
    if (response.contains(RegExp(r'(Pasos|Siguientes acciones):')))
      score += 0.5;

    // Precisión SAP
    if (response.contains(RegExp(r'SAP [A-Z]{2,4}'))) score += 0.5;

    return score.clamp(0.0, 3.0);
  }

  String selectBestResponse(List<String> responses) {
    return responses
        .reduce((a, b) => evaluateResponse(a) > evaluateResponse(b) ? a : b);
  }

  String generateFeedback(String response) {
    final score = evaluateResponse(response);
    if (score < 1.5)
      return 'Respuesta insuficiente. Mejorar: 1) Profundidad técnica 2) Estructura profesional 3) Referencias específicas';
    if (score < 2.0)
      return 'Respuesta aceptable. Mejorar: 1) Ejemplos prácticos 2) Consideraciones de implementación';
    return 'Respuesta óptima';
  }
}
