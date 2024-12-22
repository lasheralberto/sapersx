import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:sapers/main.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';

class TextEditorWithCode extends StatefulWidget {
  final TextEditingController textController;

  const TextEditorWithCode({Key? key, required this.textController})
      : super(key: key);

  @override
  _TextEditorWithCodeState createState() => _TextEditorWithCodeState();
}

class _TextEditorWithCodeState extends State<TextEditorWithCode> {
  bool _isCodeMode = false;
  bool _isDarkMode = false;
  final TextEditingController _formattedController = TextEditingController();
  final double _minHeight = 100.0; // Altura mínima inicial
  final double _maxHeight = 500.0; // Altura máxima permitida

  @override
  void initState() {
    super.initState();
    _formattedController.text = widget.textController.text;

    // Añadir listeners para detectar cambios en el texto
    widget.textController.addListener(_onTextChange);
    _formattedController.addListener(_onTextChange);
  }

  void _onTextChange() {
    setState(() {
      // Forzar rebuild para recalcular altura
    });
  }

  void _toggleCodeFormat() {
    final TextEditingController currentController =
        _isCodeMode ? _formattedController : widget.textController;

    // Obtener el texto seleccionado
    String selectedText =
        currentController.selection.textInside(currentController.text);

    if (selectedText.isNotEmpty) {
      // Si hay texto seleccionado, solo formatear esa parte
      String newText = _isCodeMode
          ? _removeCodeBlock(selectedText)
          : _addCodeBlock(selectedText);

      // Reemplazar el texto seleccionado
      final int start = currentController.selection.start;
      final int end = currentController.selection.end;

      String beforeSelection = currentController.text.substring(0, start);
      String afterSelection = currentController.text.substring(end);

      currentController.text = beforeSelection + newText + afterSelection;

      // Mantener la selección
      currentController.selection = TextSelection(
        baseOffset: start,
        extentOffset: start + newText.length,
      );
    } else {
      // Si no hay selección, formatear todo el texto
      setState(() {
        _isCodeMode = !_isCodeMode;
        if (_isCodeMode) {
          final formattedText = _formatAbapCode(widget.textController.text);
          _formattedController.text = _addCodeBlock(formattedText);
        } else {
          widget.textController.text = _formattedController.text;
        }
      });
    }
  }

  String _addCodeBlock(String text) {
    if (!text.startsWith('```') && !text.endsWith('```')) {
      return '```abap\n$text\n```';
    }
    return text;
  }

  String _removeCodeBlock(String text) {
    if (text.startsWith('```') && text.endsWith('```')) {
      return text.substring(3, text.length - 3).trim();
    }
    return text;
  }

  String _formatAbapCode(String code) {
    if (code.trim().isEmpty) return '';

    List<String> lines = code.split('\n');
    int indentLevel = 0;
    List<String> formattedLines = [];

    for (String line in lines) {
      String trimmedLine = line.trim().toUpperCase();

      if (trimmedLine.startsWith('END') ||
          trimmedLine.startsWith('ENDIF') ||
          trimmedLine.startsWith('ENDLOOP') ||
          trimmedLine.startsWith('ENDWHILE') ||
          trimmedLine.startsWith('ENDCASE') ||
          trimmedLine.startsWith('ENDTRY')) {
        indentLevel = math.max(0, indentLevel - 1);
      }

      String formattedLine = '  ' * indentLevel + line.trim();
      formattedLines.add(formattedLine);

      if (trimmedLine.startsWith('IF ') ||
          trimmedLine.startsWith('LOOP ') ||
          trimmedLine.startsWith('DO ') ||
          trimmedLine.startsWith('WHILE ') ||
          trimmedLine.startsWith('CASE ') ||
          trimmedLine.startsWith('CATCH ') ||
          trimmedLine.startsWith('TRY')) {
        indentLevel++;
      }
    }

    return formattedLines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          constraints: BoxConstraints(
            minWidth: constraints.maxWidth,
            maxWidth: constraints.maxWidth,
            minHeight: _minHeight,
            maxHeight: _maxHeight,
          ),
          child: IntrinsicHeight(
            child: Column(
              children: [
                Expanded(
                  child: Card(
                    elevation: AppStyles().getCardElevation(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppStyles().getTextFieldColor(context),
                        borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
                      ),
                      child: Stack(
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: _minHeight,
                              maxHeight: _maxHeight,
                            ),
                            child: SingleChildScrollView(
                              child: TextField(
                                controller: _isCodeMode
                                    ? _formattedController
                                    : widget.textController,
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                style: TextStyle(
                                  fontFamily: _isCodeMode ? 'monospace' : null,
                                  fontSize: 12,
                                  color:
                                      _isDarkMode ? Colors.white : Colors.black,
                                ),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
                                  ),
                                  hintText: Texts.translate(
                                      'escribeTuRespuesta', globalLanguage),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_isCodeMode)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
                                ),
                                child: const Text(
                                  'ABAP',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.format_indent_increase),
                        onPressed: _toggleCodeFormat,
                        tooltip: Texts.translate(
                            'formatearCodigoABAP', globalLanguage),
                        color: _isCodeMode ? Colors.blue : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(
                            text: _isCodeMode
                                ? _formattedController.text
                                : widget.textController.text,
                          ));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(Texts.translate(
                                  'copiarAlPortapapeles', globalLanguage)),
                            ),
                          );
                        },
                        tooltip: Texts.translate(
                            'copiarAlPortapapeles', globalLanguage),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    widget.textController.removeListener(_onTextChange);
    _formattedController.removeListener(_onTextChange);
    _formattedController.dispose();
    super.dispose();
  }
}
