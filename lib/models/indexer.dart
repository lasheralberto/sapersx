import 'dart:convert';
import 'package:http/http.dart' as http;

class PostIndexer {
  final String endpoint = "https://sapersx-568424820796.us-west1.run.app/index-posts";

  Future<Map<String, dynamic>> indexPost(Map<String, dynamic> postBody) async {
    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(postBody),
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
