import 'package:flutter/material.dart';
import 'package:sapers/main.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/posts.dart'; // Modelo de SAPReply
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';

class SAPAttachmentsViewerHeader extends StatefulWidget {
  final SAPPost reply; // Recibimos el SAPReply como input
  final Function(Map<String, dynamic>) onAttachmentOpen;

  const SAPAttachmentsViewerHeader({
    super.key,
    required this.reply,
    required this.onAttachmentOpen,
  });

  @override
  State<SAPAttachmentsViewerHeader> createState() =>
      _SAPAttachmentsViewerHeaderState();
}

class _SAPAttachmentsViewerHeaderState extends State<SAPAttachmentsViewerHeader>
    with TickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;

  bool _userHasAttachments = false;

  @override
  void initState() {
    super.initState();

// Comprobar si attachments no es nulo y no está vacío
    if (widget.reply.attachments?.isNotEmpty ?? false) {
      // Eliminar aquellos attachments que no pertenecen al autor actual
      widget.reply.attachments?.removeWhere(
        (element) => element['author'] != widget.reply.author,
      );
    }

// Actualizar _userHasAttachments dependiendo de si existen attachments o no
    if (widget.reply.attachments?.isNotEmpty ?? false) {
      _userHasAttachments = false;
    } else {
      _userHasAttachments = true;
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(-1, -1), // Comienza fuera de la pantalla (arriba)
      end: const Offset(-1, -1.1), // Finaliza en el centro
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  void _showAttachmentsList() {
    _overlayEntry = _createOverlayEntry();

    Overlay.of(context).insert(_overlayEntry!);
    _animationController
        .forward(); // Inicia la animación cuando aparece el overlay
  }

  void _hideAttachmentsList() {
    _animationController.reverse().then((value) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }); // Reverse para hacer la animación de ocultar
  }

  OverlayEntry _createOverlayEntry() {
    final attachments = widget.reply.attachments ?? [];

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Capa transparente que cubre toda la pantalla para detectar clics fuera
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _hideAttachmentsList,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          // Popup de archivos con animación
          Positioned(
            width: 280,
            child: CompositedTransformFollower(
              link: _layerLink,
              child: SlideTransition(
                position: _offsetAnimation,
                child: GestureDetector(
                  // Evita que los clics en el popup lo cierren
                  onTap: () {},
                  child: Material(
                    elevation: 8,
                    borderRadius:
                        BorderRadius.circular(AppStyles.borderRadiusValue),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppStyles.borderRadiusValue),
                      child: Container(
                        color: Colors.transparent,
                        child: attachments.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No hay archivos adjuntos'),
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Text(
                                          Texts.translate(
                                              'attachments', LanguageProvider().currentLanguage),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall,
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${attachments.length}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 1),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    itemCount: attachments.length,
                                    itemBuilder: (context, index) {
                                      final attachment = attachments[index];
                                      return InkWell(
                                        onTap: () {
                                          _hideAttachmentsList();
                                          widget.onAttachmentOpen(attachment);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                _getFileIcon(
                                                    attachment['fileName'] ??
                                                        ''),
                                                size: 20,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  attachment['fileName'] ??
                                                      'File',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: Colors.grey[800],
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: () {
          if (_overlayEntry == null) {
            _showAttachmentsList();
          } else {
            _hideAttachmentsList();
          }
        },
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _userHasAttachments == false
                  ? const Icon(
                      Icons.attach_file,
                      size: 18,
                      color: Colors.black87,
                    )
                  : const SizedBox.shrink(),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hideAttachmentsList();
    _animationController.dispose();
    super.dispose();
  }
}

// Función auxiliar para obtener el icono según la extensión
IconData _getFileIcon(String fileName) {
  final extension = fileName.split('.').last.toLowerCase();
  switch (extension) {
    case 'pdf':
      return Icons.picture_as_pdf;
    case 'doc':
    case 'docx':
      return Icons.description;
    case 'xls':
    case 'xlsx':
      return Icons.table_chart;
    case 'jpg':
    case 'jpeg':
    case 'png':
      return Icons.image;
    default:
      return Icons.insert_drive_file;
  }
}
