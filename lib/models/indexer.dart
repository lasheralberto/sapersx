import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PostIndexer {
  final String endpoint =
      "https://sapersx-568424820796.us-west1.run.app/index-posts";

  Future<Map<String, dynamic>> indexPost(Map<String, dynamic> postBody) async {
    try {
      // Crear una copia del mapa y convertir el Timestamp
      final Map<String, dynamic> serializedBody = Map.from(postBody);

      // Convertir el Timestamp a ISO string
      if (serializedBody['timestamp'] is Timestamp) {
        serializedBody['timestamp'] = (serializedBody['timestamp'] as Timestamp)
            .toDate()
            .toIso8601String();
      }

      // Asegurarse que tags y attachments sean listas vacías si son null
      serializedBody['tags'] ??= [];
      serializedBody['attachments'] ??= [];

      debugPrint("Sending to index: ${jsonEncode(serializedBody)}");

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(serializedBody),
      );

      if (response.statusCode == 200) {
        return {
          "success": true,
          "data": jsonDecode(response.body),
        };
      } else {
        return {
          "success": false,
          "error": response.body,
          "status": response.statusCode,
        };
      }
    } catch (e) {
      debugPrint('Error indexing post: $e');
      return {
        "success": false,
        "error": e.toString(),
      };
    }
  }
}

class UserIndexer {
  final String endpoint =
      "https://sapersx-568424820796.us-west1.run.app/index-users";

  Future<Map<String, dynamic>> indexUser(Map<String, dynamic> userBody) async {
    // Claves a enviar
    final keysToSend = [
      "uid",
      "username",
      "email",
      "location",
      "bio",
      "specialty",
      "hourlyRate",
      "isExpert",
      "experience",
      "website",
    ];

    // Filtrar el mapa original
    final userMap = {
      for (final k in keysToSend)
        if (userBody.containsKey(k) && userBody[k] != null) k: userBody[k]
    };

    debugPrint("userMap: $userMap");
    var userMapEncoded = jsonEncode(userMap);
    debugPrint("userMapEncoded: $userMapEncoded");

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: userMapEncoded,
      );

      if (response.statusCode == 200) {
        return {
          "success": true,
          "data": jsonDecode(response.body),
        };
      } else {
        return {
          "success": false,
          "error": response.body,
          "status": response.statusCode,
        };
      }
    } catch (e) {
      return {
        "success": false,
        "error": e.toString(),
      };
    }
  }
}
