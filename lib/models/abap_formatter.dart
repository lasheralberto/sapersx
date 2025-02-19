import 'dart:math' as math;

class ABAPCodeFormatter {
  static const _codeBlockWrapper = '```abap';
  static const _indentSize = 2;
  final _stack = <String>[];
  int _indentLevel = 0;
  bool _inChain = false;
  int _chainIndent = 0;

  // Expresiones regulares optimizadas
  static final blockStartRegex = RegExp(
    r'^\s*(IF|LOOP|DO|WHILE|CASE|METHOD|CLASS|FUNCTION|FORM|MODULE|PROVIDE|SELECT|TRY|CATCH|CLEANUP|CHECK|AT\s+.*|DATA|TYPES|CONSTANTS|STATICS|TABLES|TABLES|BEGIN\s+OF|END\s+OF|REPORT|INCLUDE|TYPE-POOL|INTERFACE|PUBLIC|PRIVATE|PROTECTED|CREATE\s+(PUBLIC|PRIVATE|PROTECTED)|RAISE|WHEN|ELSE|ELSEIF|DEFINE|ENHANCEMENT-SECTION|END-(CLASS|METHOD|FUNCTION|FORM|MODULE|PROVIDE|SELECT|TRY|ENHANCEMENT-SECTION|DEFINE)|IMPLEMENTATION)\b',
    caseSensitive: false,
  );

  static final blockEndRegex = RegExp(
    r'^\s*(ENDIF|ENDLOOP|ENDDO|ENDCASE|ENDMETHOD|ENDCLASS|ENDFUNCTION|ENDFORM|ENDMODULE|ENDSELECT|ENDTRY|ENDCATCH|ENDCLEANUP|ENDAT|ENDWHILE|ENDENHANCEMENT-SECTION|END-OF-DEFINITION)\b',
    caseSensitive: false,
  );

  static final _chainOperatorRegex = RegExp(r':\s*(?!.*::)');
  static final _commentRegex = RegExp(r'^\s*(\*|")');
  static final _stringLiteralRegex = RegExp(r'''''');
  static final _endOfStatementRegex = RegExp(r'\.\s*$');

  String formatCode(String code) {
    final lines = code.split('\n');
    final formattedLines = <String>[];
    _resetState();

    for (var line in lines) {
      line = _processLine(line);
      formattedLines.add(line);
    }

    return formattedLines.join('\n');
  }

  String _processLine(String line) {
    final originalLine = line;
    line = line.trim();

    if (line.isEmpty) return '';

    // Manejar comentarios y literales de texto
    if (_isComment(line) || _isInStringLiteral) {
      return _handleSpecialCases(originalLine, line);
    }

    // Manejar bloques de código
    final isBlockEnd = blockEndRegex.hasMatch(line);
    final isBlockStart = blockStartRegex.hasMatch(line);

    adjustIndentLevel(isBlockStart, isBlockEnd);

    // Manejar operadores de encadenamiento
    if (_chainOperatorRegex.hasMatch(line)) {
      return handleChainOperator(line);
    }

    // Construir línea formateada
    final formattedLine = buildFormattedLine(line, originalLine);

    // Manejar fin de declaraciones
    if (_endOfStatementRegex.hasMatch(line)) {
      handleEndOfStatement();
    }

    return formattedLine;
  }

  void adjustIndentLevel(bool isBlockStart, bool isBlockEnd) {
    if (isBlockEnd && _indentLevel > 0) {
      _indentLevel = math.max(0, _indentLevel - 1);
      if (_stack.isNotEmpty) _stack.removeLast();
    }

    if (isBlockStart) {
      _indentLevel++;
      _stack.add(_currentIndent);
    }
  }

  String handleChainOperator(String line) {
    final parts = line.split(_chainOperatorRegex);
    _inChain = true;
    _chainIndent = _indentLevel + 1;

    final formattedParts = parts.asMap().entries.map((entry) {
      final index = entry.key;
      final part = entry.value.trim();
      final indent = index == 0 ? _indentLevel : _chainIndent;
      return '${'  ' * indent}$part';
    }).toList();

    return formattedParts.join(':\n');
  }

  String buildFormattedLine(String line, String originalLine) {
    final indent = _inChain ? _chainIndent : _indentLevel;
    final leadingWhitespace = originalLine.substring(0, originalLine.indexOf(line));
    return '$leadingWhitespace${'  ' * indent}$line';
  }

  void handleEndOfStatement() {
    if (_inChain) {
      _inChain = false;
      _chainIndent = 0;
    }
  }

  bool _isComment(String line) => _commentRegex.hasMatch(line);
  bool get _isInStringLiteral => _stringLiteralRegex.hasMatch(_currentIndent);

  String _handleSpecialCases(String originalLine, String line) {
    final indent = _inChain ? _chainIndent : _indentLevel;
    return '${'  ' * indent}$originalLine';
  }

  String get _currentIndent => _stack.isNotEmpty ? _stack.last : '';
  void _resetState() {
    _indentLevel = 0;
    _inChain = false;
    _chainIndent = 0;
    _stack.clear();
  }

  String wrapCodeBlock(String code) {
    final trimmedCode = code.trim();
    if (trimmedCode.startsWith(_codeBlockWrapper) && trimmedCode.endsWith('```')) {
      return code;
    }
    return '$_codeBlockWrapper\n$trimmedCode\n```';
  }

  String unwrapCodeBlock(String code) {
    return code
        .replaceAll(RegExp(r'^```abap\n', multiLine: true), '')
        .replaceAll(RegExp(r'\n```$', multiLine: true), '')
        .trim();
  }
}