import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;

class GoogleSecretManager {
  final String projectId;
  final String secretName;
  final String serviceAccountFile;

  GoogleSecretManager({
    required this.projectId,
    required this.secretName,
    required this.serviceAccountFile,
  });

  // Método para cargar las credenciales de la cuenta de servicio
  Future<ServiceAccountCredentials> _loadCredentials() async {
    // Lee las credenciales desde el rootBundle, donde 'assets/service_account.json' es el path en tu proyecto.
    final serviceAccountJson =
        await rootBundle.loadString('assets/sapersx_sa.json');

    // Convierte el JSON a un objeto ServiceAccountCredentials
    return ServiceAccountCredentials.fromJson(serviceAccountJson);
  }

  // Método para obtener un cliente autenticado mediante la cuenta de servicio
  Future<AutoRefreshingAuthClient> _getAuthClient() async {
    final credentials = await _loadCredentials();
    const scopes = ['https://www.googleapis.com/auth/cloud-platform'];
    final client = await clientViaServiceAccount(credentials, scopes);
    return client;
  }

  // Método para obtener el token de acceso
  Future<String> _getAccessToken() async {
    final client = await _getAuthClient();
    return client.credentials.accessToken.data;
  }

  // Método para obtener el secreto desde Google Secret Manager
  Future<String> getSecret() async {
    final accessToken = await _getAccessToken();

    final response = await http.get(
      Uri.parse(
          'https://secretmanager.googleapis.com/v1/projects/$projectId/secrets/$secretName/versions/latest:access'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final secretData = jsonDecode(response.body);
      final secretBase64 = secretData['payload']['data'];
      final secret = utf8.decode(base64.decode(secretBase64));
      return secret;
    } else {
      throw Exception('Error accediendo al secreto: ${response.statusCode}');
    }
  }
}
