
import 'package:flutter/material.dart';
import 'package:sapers/components/widgets/postcard.dart';

class FeedActions{
  void showReplySheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Importante para que el teclado no tape el campo
    backgroundColor: Colors.transparent,
    builder: (context) => ReplyBottomSheet(
      hintText: 'Responde a este post...', // Opcional
      onSubmitted: (String text) {
        // Manejar el texto enviado
        print('Respuesta enviada: $text');
      },
    ),
  );
}
}