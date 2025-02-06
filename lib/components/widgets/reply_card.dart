import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sapers/components/widgets/attachmentsviewer.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/posts.dart';
import 'package:url_launcher/url_launcher.dart';

class ReplyCard extends StatefulWidget {
  final SAPReply reply;
  final String postId;
  final String currentUserId; // ID del usuario actual

  const ReplyCard({
    Key? key,
    required this.reply,
    required this.postId,
    required this.currentUserId,
  }) : super(key: key);

  @override
  _ReplyCardState createState() => _ReplyCardState();
}

class _ReplyCardState extends State<ReplyCard> {
  bool _authorInReply = false; // Indica si el usuario ya ha votado

  @override
  void initState() {
    super.initState();
    _checkIfUserHasVoted();
  }

  /// Comprueba en Firebase si el usuario ya ha votado para esta respuesta
  void _checkIfUserHasVoted() async {
    bool hasVoted = await FirebaseService().isAuthorInReply(
      widget.postId,
      widget.reply.id,
      widget.currentUserId,
    );
    setState(() {
      _authorInReply = hasVoted;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Colores de ejemplo para la tarjeta, borde y acentos
    final Color _replyCardColor = Colors.white;
    final Color _borderColor = Colors.grey;
    final Color _accentOrange = Colors.orange;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: _replyCardColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _accentOrange.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Método que construye el encabezado de la respuesta
                    _buildReplyHeader(widget.reply),
                    const SizedBox(height: 16),
                    // Método que construye el contenido (puede ser código u otro texto)
                    _buildCodeContent(widget.reply.content),
                    if (widget.reply.attachments != null &&
                        widget.reply.attachments!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      AttachmentsViewer(
                        reply: widget.reply,
                        onAttachmentOpen: (attachment) {
                          if (attachment['url'] != null) {
                            launchUrl(
                              Uri.parse(attachment['url']),
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Botón de votación con efecto splash
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        splashColor: Colors.amber.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8.0),
                        onTap: () async {
                          if (_authorInReply) {
                            // Si ya ha votado, se elimina el voto (decrementar y remover el ID)
                            await FirebaseService().voteForReply(
                              widget.reply.postId,
                              widget.reply.id,
                              widget.currentUserId,
                              -1,
                            );
                          } else {
                            // Si no ha votado, se añade el voto (incrementar y añadir el ID)
                            await FirebaseService().voteForReply(
                              widget.reply.postId,
                              widget.reply.id,
                              widget.currentUserId,
                              1,
                            );
                          }
                          // Cambiamos el estado del botón
                          setState(() {
                            _authorInReply = !_authorInReply;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.thumb_up_alt_outlined,
                            size: 20,
                            color: _authorInReply ? Colors.amber : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Widget que muestra el número de votos, si el campo 'replyVotes' existe y es mayor a 0
        if (widget.reply.toMap().containsKey('replyVotes') &&
            widget.reply.replyVotes > 0)
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.red, // Color de fondo para el contador de votos
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                '${widget.reply.replyVotes}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16, // Ajusta el tamaño de fuente según tu estilo
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Ejemplo de método que construye el encabezado de la respuesta
  Widget _buildReplyHeader(SAPReply reply) {
    return Row(
      children: [
        // Aquí puedes colocar, por ejemplo, la imagen de perfil, el nombre del usuario, etc.
        Text(
          reply.author,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        // Agrega más elementos según necesites
      ],
    );
  }

  /// Ejemplo de método que construye el contenido de la respuesta (puede ser código o texto)
  Widget _buildCodeContent(String content) {
    return Text(
      content,
      style: const TextStyle(fontFamily: 'monospace'),
    );
  }
}
