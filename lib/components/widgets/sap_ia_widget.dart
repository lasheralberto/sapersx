import 'dart:async';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/sap_ai_assistant.dart';
import 'package:sapers/models/texts.dart';

class SAPAIAssistantWidget extends StatefulWidget {
  final String username;
  final bool isPanelVisible;

  const SAPAIAssistantWidget({
    Key? key,
    required this.username,
    required this.isPanelVisible,
  }) : super(key: key);

  @override
  _SAPAIAssistantWidgetState createState() => _SAPAIAssistantWidgetState();
}

class _SAPAIAssistantWidgetState extends State<SAPAIAssistantWidget> {
  final TextEditingController _queryController = TextEditingController();
  final SAPAIAssistantService _assistantService = SAPAIAssistantService();
  String _currentResponse = '';
  String _animatedResponse = '';
  bool _isLoading = false;
  Timer? _animationTimer;

  Future<void> _sendQuery() async {
    if (_queryController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _currentResponse = '';
      _animatedResponse = '';
    });

    try {
      final response = await _assistantService.generateAIResponse(
          query: _queryController.text, username: widget.username);

      _startTextAnimation(response);
    } catch (e) {
      setState(() {
        _currentResponse = 'Error al procesar la solicitud';
        _isLoading = false;
      });
    }
  }

  void _startTextAnimation(String fullText) {
    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_animatedResponse.length < fullText.length) {
        setState(() {
          _animatedResponse += fullText[_animatedResponse.length];
          _currentResponse = _animatedResponse;
        });
      } else {
        timer.cancel();
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: widget.isPanelVisible
          ? Container(
              key: const ValueKey('chat-visible'),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _queryController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      hintStyle: const TextStyle(
                        fontSize: 12.0,
                        color: Colors.grey,
                      ),
                      hintText: Texts.translate(
                          'askMe',
                          Provider.of<LanguageProvider>(context)
                              .currentLanguage),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Symbols.chat,
                          size: 20.0,
                        ),
                        onPressed: _sendQuery,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              _currentResponse,
                              style: const TextStyle(
                                // Optional: Add styling to make animation more smooth
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            )
          : Container(
              key: const ValueKey('chat-hidden'),
            ),
    );
  }
}
