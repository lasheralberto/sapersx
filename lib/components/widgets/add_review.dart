import 'package:flutter/material.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/styles.dart';

class AddReviewDialog extends StatefulWidget {
  final String username; // Nombre del usuario al que se le añadirá la reseña

  const AddReviewDialog({super.key, required this.username});

  @override
  State<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<AddReviewDialog> {
  final _reviewController = TextEditingController();
  double _rating = 3.0; // Valor inicial para la puntuación

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var mediaquery = MediaQuery.of(context).size;

    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
            maxWidth: mediaquery.width / 1.5, maxHeight: mediaquery.height / 2),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Añadir Reseña',
                      style: AppStyles().getTextStyle(context),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reviewController,
                decoration: const InputDecoration(
                  labelText: 'Escribe un comentario',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Puntuación:', style: AppStyles().getTextStyle(context)),
                  DropdownButton<double>(
                    value: _rating,
                    items: List.generate(5, (index) {
                      final value = (index + 1).toDouble();
                      return DropdownMenuItem(
                        value: value,
                        child: Text('$value ⭐'),
                      );
                    }),
                    onChanged: (value) {
                      setState(() {
                        _rating = value!;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                children: [
                  TextButton(
                    style: AppStyles().getButtonStyle(context),
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancelar',
                        style: AppStyles().getTextStyle(context)),
                  ),
                  FilledButton(
                    style: AppStyles().getButtonStyle(context),
                    onPressed: () async {
                      await FirebaseService().addReview(
                        widget.username,
                        _reviewController.text,
                        _rating,
                      );
                      Navigator.pop(context,true);
                    },
                    child: Text('Añadir Reseña',
                        style: AppStyles().getTextStyle(context)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
