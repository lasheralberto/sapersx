import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sapers/models/posts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sapers/models/styles.dart';

class AttachmentsCarousel extends StatefulWidget {
  final SAPPost reply;
  final Function(Map<String, dynamic>) onAttachmentOpen;

  const AttachmentsCarousel({
    Key? key,
    required this.reply,
    required this.onAttachmentOpen,
  }) : super(key: key);

  @override
  State<AttachmentsCarousel> createState() => _AttachmentsCarouselState();
}

class _AttachmentsCarouselState extends State<AttachmentsCarousel> {
  @override
  Widget build(BuildContext context) {
    // Si no hay adjuntos, no muestra nada
    if (widget.reply.attachments == null || widget.reply.attachments!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Filtrar solo las imágenes
    final imageAttachments = widget.reply.attachments!.where((attachment) {
      final String type = attachment['type'] ?? '';
      return type.startsWith('image/');
    }).toList();

    // Si no hay imágenes, no muestra nada
    if (imageAttachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Título de archivos adjuntos
        Text(
          'Imágenes adjuntas',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        // Carrusel horizontal de miniaturas
        SizedBox(
          height: 80, // Altura fija para las miniaturas
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: imageAttachments.length,
            itemBuilder: (context, index) {
              final attachment = imageAttachments[index];
              return _buildThumbnail(attachment);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnail(Map<String, dynamic> attachment) {
    final String url = attachment['url'] ?? '';
    final String name = attachment['name'] ?? 'Imagen';

    return GestureDetector(
      onTap: () => widget.onAttachmentOpen(attachment),
      child: Container(
        width: 80,
        height: 80,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue - 1),
          child: url.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                )
              : const Center(child: Icon(Icons.image)),
        ),
      ),
    );
  }
}

class ReplyAttachmentsCarousel extends StatelessWidget {
  final SAPReply reply;
  final Function(Map<String, dynamic>) onAttachmentOpen;

  const ReplyAttachmentsCarousel({
    Key? key,
    required this.reply,
    required this.onAttachmentOpen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Si no hay adjuntos, no muestra nada
    if (reply.attachments == null || reply.attachments!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Filtrar solo las imágenes
    final imageAttachments = reply.attachments!.where((attachment) {
      final String type = attachment['fileName'] ?? '';
      return type.endsWith('.jpg') ||
          type.endsWith('.jpeg') ||
          type.endsWith('.png');
    }).toList();

    // Si no hay imágenes, no muestra nada
    if (imageAttachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Título de archivos adjuntos
        Text(
          'Imágenes adjuntas',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        // Carrusel horizontal de miniaturas
        SizedBox(
          height: 80, // Altura fija para las miniaturas
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: imageAttachments.length,
            itemBuilder: (context, index) {
              final attachment = imageAttachments[index];
              return FirebaseImageThumbnail(
                attachment: attachment,
                onTap: onAttachmentOpen,
              );
            },
          ),
        ),
      ],
    );
  }
}

class FirebaseImageThumbnail extends StatefulWidget {
  final Map<String, dynamic> attachment;
  final Function(Map<String, dynamic>) onTap;

  const FirebaseImageThumbnail({
    Key? key,
    required this.attachment,
    required this.onTap,
  }) : super(key: key);

  @override
  State<FirebaseImageThumbnail> createState() => _FirebaseImageThumbnailState();
}

class _FirebaseImageThumbnailState extends State<FirebaseImageThumbnail> {
  String? _imageUrl;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadImageUrl();
  }

  Future<void> _loadImageUrl() async {
    try {
      // Primero intenta usar la URL proporcionada directamente
      final providedUrl = widget.attachment['url'] as String?;

      if (providedUrl != null && providedUrl.isNotEmpty) {
        setState(() {
          _imageUrl = providedUrl;
          _isLoading = false;
        });
      }
      // Si no hay URL o la URL es inválida, intenta obtenerla de Firebase Storage
      else if (widget.attachment['path'] != null) {
        final path = widget.attachment['path'] as String;
        final ref = FirebaseStorage.instance.ref().child(path);
        final url = await ref.getDownloadURL();

        if (mounted) {
          setState(() {
            _imageUrl = url;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'No URL or path found';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading image URL: $e');
      }
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onTap(widget.attachment),
      child: Container(
        width: 80,
        height: 80,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue - 1),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_errorMessage != null) {
      return const Center(
        child: Icon(Icons.error_outline, color: Colors.red),
      );
    }

    if (_imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: _imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(Icons.broken_image, color: Colors.orange),
        ),
      );
    }

    return const Center(
      child: Icon(Icons.image),
    );
  }
}
