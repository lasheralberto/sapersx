
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:sapers/components/widgets/mesmorphic_popup.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/texts.dart';

class UtilsSapers {
  showTextPopup(context, message) {
    showDialog(
        context: context,
        builder: (context) => MesomorphicPopup(
              text: message,
              onClose: () => Navigator.pop(context),
            ));
  }

  String generateSimpleUID() {
    final random = Random();
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final randomNumber = random.nextInt(100000);
    return '$timestamp-$randomNumber';
  }

  ///Usada para el clipboard de imágenes
  Future<Uint8List> readImages() async {
    final imageBytes = await Pasteboard.image;
    if (imageBytes != null) {
      return imageBytes;
    } else {
      return Uint8List(0);
    }
  }

  List<Map<String, dynamic>> convertPlatformFilesToAttachments(
      List<PlatformFile> files) {
    return files
        .map((file) => {
              'name': file.name,
              'size': file.size,
              'type': file.extension ?? 'unknown',
              // You might want to generate a temporary URL or handle this differently
              //'url': file.path ?? '',
            })
        .toList();
  }

  Future<List<PlatformFile>?> pickFiles(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'pdf', 'txt', 'doc', 'docx'],
      );
      return result?.files;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar archivos: $e')),
      );
      return null;
    }
  }

  String userUniqueUid(String email) {
    // Normaliza el email (elimina espacios y convierte a minúsculas)
    final normalizedEmail = email.trim().toLowerCase();

    // Convierte el email en bytes
    final bytes = utf8.encode(normalizedEmail);

    // Genera un hash SHA-256 (puedes usar SHA-1 si prefieres)
    final hash = sha256.convert(bytes);

    // Convierte el hash en una cadena hexadecimal
    return hash.toString();
  }

  //Función para obtener un id unico para las replies de los posts basado en el usuario loguado y la fecha
  String getReplyId(context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return '';
    } else {
      return user.uid + DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  /// Método para formatear fecha
  String formatTimestampJoinDate(String timestampString) {
    try {
      // Ejemplo de string: "Timestamp(seconds=1738442893, nanoseconds=742822000)"
      final secondsPattern = RegExp(r'seconds=(\d+)');
      final nanosecondsPattern = RegExp(r'nanoseconds=(\d+)');

      final secondsMatch = secondsPattern.firstMatch(timestampString);
      final nanosecondsMatch = nanosecondsPattern.firstMatch(timestampString);

      if (secondsMatch == null || nanosecondsMatch == null) {
        return '';
      }

      final seconds = int.parse(secondsMatch.group(1)!);
      final nanoseconds = int.parse(nanosecondsMatch.group(1)!);

      final timestamp = Timestamp(seconds, nanoseconds);
      final DateTime dateTime = timestamp.toDate();

      return DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  /// Método para formatear fecha
  String formatDateStringWithTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('dd/MM/yyyy hh:mm').format(dateTime);
    } catch (e) {
      return ''; // En caso de error
    }
  }

  String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1)
      return Texts.translate('now', LanguageProvider().currentLanguage);
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  String getContentType(String fileName) {
    String ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }
}
