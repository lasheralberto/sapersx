import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  static const String _apiKey = 'AIzaSyAqsIe_3BGWyDV_W1ooonn1BtDt4nFTF4I'; // Reemplaza con tu API Key

  /// Obtiene la ciudad a partir de las coordenadas (latitud y longitud).
  static Future<String?> getCityFromLatLng(double lat, double lng) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$_apiKey',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Verifica si la respuesta contiene resultados
        if (data['status'] == 'OK') {
          final results = data['results'] as List;

          // Busca la ciudad en los componentes de la dirección
          for (var result in results) {
            final addressComponents = result['address_components'] as List;
            for (var component in addressComponents) {
              final types = component['types'] as List;
              if (types.contains('locality')) {
                return component['long_name'] as String;
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error obteniendo la ciudad: $e');
    }

    return null; // Si no se encuentra la ciudad
  }
}