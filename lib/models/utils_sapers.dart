import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:sapers/models/styles.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:sapers/components/widgets/mesmorphic_popup.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/texts.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UtilsSapers {
  Widget buildShimmerEffect(int lines, Widget shimmerWidget) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: AppStyles.colorAvatarBorderLighter,
      child: Column(
        children: List.generate(lines, (index) => shimmerWidget),
      ),
    );
  }

  Widget buildAvatarIconShimmer({double size = 10.0}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: Icon(
          Icons.person,
          size: size * 0.6,
          color: Colors.grey[300],
        ),
      ),
    );
  }

  Widget buildShimmerPost(context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Container(
        width: MediaQuery.of(context).size.width / 1.5,
        height: 180, // 🔽 Altura más baja
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + Nombre + Fecha
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    height: 32,
                    width: 32,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 8,
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 8,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            // Título
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Cuerpo reducido
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Botón
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                height: 24,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildShimmerLine() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        height: 20,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static List<TextSpan> parsePostContent(String content) {
    final List<TextSpan> spans = [];
    final lines = content.split('\n');

    const normalStyle =
        TextStyle(fontSize: 15, color: Colors.black87, height: 1.5);
    const boldStyle =
        TextStyle(fontWeight: FontWeight.bold, color: Colors.black87);
    const italicStyle =
        TextStyle(fontStyle: FontStyle.italic, color: Colors.black87);
    final codeStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 13,
      backgroundColor: const Color(0xFFF6F8FA),
      color: const Color(0xFFEA7E00),
      letterSpacing: 0.5,
    );
    const linkStyle = TextStyle(
      color: Colors.blueAccent,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w500,
    );

    final heading1Style = TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        height: 2.2);
    final heading2Style = TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
        height: 2.0);
    final bulletStyle =
        TextStyle(fontSize: 15, height: 1.6, color: Colors.black87);

    TextSpan _parseLineWithMarkup(String line) {
      final List<TextSpan> innerSpans = [];
      int index = 0;

      while (index < line.length) {
        final boldMatch = RegExp(r'\*\*(.+?)\*\*').matchAsPrefix(line, index);
        final codeMatch = RegExp(r'`(.+?)`').matchAsPrefix(line, index);
        final italicMatch = RegExp(r'_([^_]+)_').matchAsPrefix(line, index);
        final linkMatch =
            RegExp(r'\[([^\]]+)\]\(([^)]+)\)').matchAsPrefix(line, index);

        final matches = [boldMatch, codeMatch, italicMatch, linkMatch]
            .where((m) => m != null)
            .toList();

        if (matches.isEmpty) {
          innerSpans.add(TextSpan(
            text: line.substring(index),
            style: normalStyle,
          ));
          break;
        }

        matches.sort((a, b) => a!.start.compareTo(b!.start));
        final match = matches.first!;
        if (match.start > index) {
          innerSpans.add(TextSpan(
            text: line.substring(index, match.start),
            style: normalStyle,
          ));
        }

        if (match == boldMatch) {
          innerSpans.add(TextSpan(text: boldMatch!.group(1), style: boldStyle));
          index = boldMatch.end;
        } else if (match == codeMatch) {
          innerSpans.add(TextSpan(text: codeMatch!.group(1), style: codeStyle));
          index = codeMatch.end;
        } else if (match == italicMatch) {
          innerSpans
              .add(TextSpan(text: italicMatch!.group(1), style: italicStyle));
          index = italicMatch.end;
        } else if (match == linkMatch) {
          final text = linkMatch!.group(1)!;
          final url = linkMatch.group(2)!;

          innerSpans.add(
            TextSpan(
              text: '🔗 $text',
              style: linkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
            ),
          );
          index = linkMatch.end;
        }
      }

      return TextSpan(children: innerSpans);
    }

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        spans.add(const TextSpan(text: '\n'));
        continue;
      }

      // Heading
      if (line.startsWith('#')) {
        final level = RegExp(r'^#+').firstMatch(line)?.group(0)?.length ?? 1;
        final headingText = line.replaceFirst(RegExp(r'^#+'), '').trim();
        final style = level == 1 ? heading1Style : heading2Style;
        spans.add(TextSpan(text: '$headingText\n\n', style: style));
      }

      // Bullet points
      else if (line.startsWith('* ') || line.startsWith('- ')) {
        final bulletText = '• ${line.substring(2).trim()}\n';
        spans.add(TextSpan(text: bulletText, style: bulletStyle));
      }

      // Paragraph
      else {
        spans.add(_parseLineWithMarkup(line));
        spans.add(const TextSpan(text: '\n\n'));
      }
    }

    return spans;
  }

  showTextPopup(context, message) {
    showDialog(
        context: context,
        builder: (context) => MesomorphicPopup(
              text: message,
              onClose: () => Navigator.pop(context),
            ));
  }

  Future<List<double>> getLocationOfUser() async {
    LocationData location = await Location().getLocation();
    double lat = location.latitude ?? 0.0;
    double long = location.longitude ?? 0.0;
    return [lat, long];
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
