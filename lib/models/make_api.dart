import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> makePostRequest(
    String urlParam, Map<String, dynamic> payloadParam) async {
  // URL a la que se enviará la solicitud
  final url = Uri.parse(urlParam);

  // Payload en formato JSON
  final payload = payloadParam;

  try {
    // Realizar la solicitud POST
    await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(payload),
    );
  } catch (e) {}
}
