import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sapers/main.dart';
import 'package:sapers/models/abap_formatter.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';

class TextEditorWithCode extends StatefulWidget {
  final TextEditingController textController;
  final String globalLanguage;
  final Function(List<PlatformFile>)? onFilesSelected;

  const TextEditorWithCode({
    super.key,
    required this.textController,
    required this.globalLanguage,
    this.onFilesSelected,
  });

  @override
  _TextEditorWithCodeState createState() => _TextEditorWithCodeState();
}

class _TextEditorWithCodeState extends State<TextEditorWithCode> {
  bool _isCodeMode = false;
  late final TextEditingController _formattedController;
  final double _minHeight = 100.0;
  final double _maxHeight = 500.0;
  final FocusNode _focusNode = FocusNode();
  final ABAPCodeFormatter _abapFormatter = ABAPCodeFormatter();

  @override
  void initState() {
    super.initState();
    _formattedController =
        TextEditingController(text: widget.textController.text);
    widget.textController.addListener(_syncControllers);
    _formattedController.addListener(_syncControllers);
  }

  void _syncControllers() {
    if (_isCodeMode) {
      widget.textController.text = _formattedController.text;
    } else {
      _formattedController.text = widget.textController.text;
    }
  }

  Future<void> _handleFileSelection() async {
    final files = await UtilsSapers().pickFiles(context);
    if (files != null && files.isNotEmpty) {
      widget.onFilesSelected?.call(files);
    }
  }

  void _toggleCodeFormat() {
    final selection = _getCurrentSelection();
    final isTextSelected = selection.baseOffset != selection.extentOffset;

    setState(() {
      if (isTextSelected) {
        _handleSelectedTextFormat(selection);
      } else {
        _isCodeMode = !_isCodeMode;
        _fullTextFormatting();
      }
    });
  }

  TextSelection _getCurrentSelection() {
    return _isCodeMode
        ? _formattedController.selection
        : widget.textController.selection;
  }

  void _handleSelectedTextFormat(TextSelection selection) {
    final controller =
        _isCodeMode ? _formattedController : widget.textController;
    final text = controller.text;
    final selectedText = text.substring(selection.start, selection.end);

    final newText = _isCodeMode
        ? _abapFormatter.unwrapCodeBlock(selectedText)
        : _abapFormatter.wrapCodeBlock(_abapFormatter.formatCode(selectedText));

    final newValue = text.replaceRange(selection.start, selection.end, newText);
    controller.text = newValue;
    controller.selection = TextSelection.collapsed(
      offset: selection.start + newText.length,
    );
  }

  void _fullTextFormatting() {
    if (_isCodeMode) {
      final rawText = widget.textController.text;
      final formattedAbap = _abapFormatter.formatCode(rawText);
      _formattedController.text = _abapFormatter.wrapCodeBlock(formattedAbap);
    } else {
      final wrappedCode = _formattedController.text;
      widget.textController.text = _abapFormatter.unwrapCodeBlock(wrappedCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.dividerColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: _minHeight,
              maxHeight: _maxHeight,
            ),
            child: Stack(
              children: [
                TextField(
                  controller: _isCodeMode
                      ? _formattedController
                      : widget.textController,
                  focusNode: _focusNode,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: TextStyle(
                    fontFamily: _isCodeMode ? 'RobotoMono' : null,
                    fontSize: 14,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: Texts.translate(
                        'escribeTuRespuesta', widget.globalLanguage),
                    contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 50),
                    hintStyle: TextStyle(
                      color: theme.hintColor,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (_isCodeMode)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ABAP',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _buildToolbar(theme),
        ],
      ),
    );
  }

  Widget _buildToolbar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.dividerColor))),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.attach_file,
              color: theme.primaryColor,
              size: 22,
            ),
            onPressed: _handleFileSelection,
            tooltip: Texts.translate('addAttachment', widget.globalLanguage),
          ),
          IconButton(
            icon: Icon(
              Icons.code_rounded,
              color: _isCodeMode ? theme.primaryColor : theme.iconTheme.color,
              size: 22,
            ),
            onPressed: _toggleCodeFormat,
            tooltip:
                Texts.translate('formatearCodigoABAP', widget.globalLanguage),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(
              Icons.copy_rounded,
              color: theme.iconTheme.color,
              size: 20,
            ),
            onPressed: _copyToClipboard,
            tooltip:
                Texts.translate('copiarAlPortapapeles', widget.globalLanguage),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard() {
    final text =
        _isCodeMode ? _formattedController.text : widget.textController.text;

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            Texts.translate('copiarAlPortapapeles', widget.globalLanguage)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.textController.removeListener(_syncControllers);
    _formattedController.removeListener(_syncControllers);
    _formattedController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
