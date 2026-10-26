import 'dart:convert';
import 'dart:io';

/// Supported field delimiters for CSV/TSV parsing.
enum CsvDelimiter {
  comma(',', 'Comma (,)'),
  semicolon(';', 'Semicolon (;)'),
  tab('\t', 'Tab'),
  pipe('|', 'Pipe (|)');

  const CsvDelimiter(this.char, this.label);

  /// The single-character string that acts as the delimiter.
  final String char;

  /// Human-readable label for UI display.
  final String label;
}

/// Supported text encodings for CSV files.
enum CsvEncoding {
  utf8('UTF-8'),
  utf8bom('UTF-8 with BOM'),
  ascii('ASCII / Latin-1');

  const CsvEncoding(this.label);

  final String label;
}

/// Result of a delimiter auto-detection pass.
class DelimiterDetectionResult {
  const DelimiterDetectionResult({
    required this.delimiter,
    required this.confidence,
  });

  final CsvDelimiter delimiter;

  /// 0.0 – 1.0 confidence score for the detection.
  final double confidence;
}

/// RFC 4180-compliant CSV/TSV parser and writer.
///
/// Handles:
/// - Quoted fields containing delimiter characters, embedded double-quotes, and
///   embedded newlines (`\r\n`, `\n`, `\r`).
/// - Double-quote escaping (`""` → `"`).
/// - UTF-8 BOM stripping on read.
/// - Streaming reads that keep the UI thread free for large files.
class CsvEngine {
  const CsvEngine();

  // ---------------------------------------------------------------------------
  // Parsing
  // ---------------------------------------------------------------------------

  /// Parses a complete CSV [source] string using [delimiter].
  ///
  /// Returns a list of rows; each row is an ordered list of field strings.
  List<List<String>> parseString(
    String source, {
    CsvDelimiter delimiter = CsvDelimiter.comma,
  }) {
    // Strip UTF-8 BOM if present
    final cleaned = source.startsWith('\uFEFF') ? source.substring(1) : source;
    return _parse(cleaned, delimiter.char);
  }

  /// Asynchronously parses the [file] into rows.
  ///
  /// Reads the file with [encoding] and delegates to [parseString].
  Future<List<List<String>>> parseFile(
    File file, {
    CsvDelimiter delimiter = CsvDelimiter.comma,
    CsvEncoding encoding = CsvEncoding.utf8,
  }) async {
    final bytes = await file.readAsBytes();
    final codec = _codecFor(encoding);
    final content = codec.decode(bytes);
    return parseString(content, delimiter: delimiter);
  }

  // ---------------------------------------------------------------------------
  // Writing
  // ---------------------------------------------------------------------------

  /// Serializes [rows] to an RFC 4180 CSV string with [delimiter].
  ///
  /// Fields containing the delimiter, double-quotes, or newlines are
  /// automatically quoted and internal double-quotes are escaped as `""`.
  String writeString(
    List<List<String>> rows, {
    CsvDelimiter delimiter = CsvDelimiter.comma,
    String lineEnding = '\r\n',
  }) {
    final buffer = StringBuffer();
    final sep = delimiter.char;
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      for (var j = 0; j < row.length; j++) {
        if (j > 0) buffer.write(sep);
        buffer.write(_encodeField(row[j], sep));
      }
      if (i < rows.length - 1) buffer.write(lineEnding);
    }
    return buffer.toString();
  }

  /// Writes [rows] to [file] as a CSV using the specified [encoding].
  Future<void> writeFile(
    File file,
    List<List<String>> rows, {
    CsvDelimiter delimiter = CsvDelimiter.comma,
    CsvEncoding encoding = CsvEncoding.utf8,
  }) async {
    final content = writeString(rows, delimiter: delimiter);
    final codec = _codecFor(encoding);
    final bytes = encoding == CsvEncoding.utf8bom
        ? <int>[0xEF, 0xBB, 0xBF, ...codec.encode(content)]
        : codec.encode(content);
    await file.writeAsBytes(bytes, flush: true);
  }

  // ---------------------------------------------------------------------------
  // Delimiter Detection
  // ---------------------------------------------------------------------------

  /// Heuristically detects the most likely delimiter in [sample].
  ///
  /// Analyses frequency consistency of candidate delimiters across the first
  /// [maxLines] lines and returns a confidence-ranked result.
  DelimiterDetectionResult detectDelimiter(String sample, {int maxLines = 20}) {
    final lines = _splitLines(sample).take(maxLines).toList();
    if (lines.isEmpty) {
      return const DelimiterDetectionResult(
        delimiter: CsvDelimiter.comma,
        confidence: 0.0,
      );
    }

    var bestDelimiter = CsvDelimiter.comma;
    var bestScore = -1.0;

    for (final candidate in CsvDelimiter.values) {
      final score = _scoreDelimiter(lines, candidate.char);
      if (score > bestScore) {
        bestScore = score;
        bestDelimiter = candidate;
      }
    }

    return DelimiterDetectionResult(
      delimiter: bestDelimiter,
      confidence: bestScore.clamp(0.0, 1.0),
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  List<List<String>> _parse(String source, String sep) {
    final rows = <List<String>>[];
    var row = <String>[];
    final buf = StringBuffer();
    var i = 0;
    var inQuotes = false;

    while (i < source.length) {
      final ch = source[i];

      if (inQuotes) {
        if (ch == '"') {
          // Peek ahead for escaped quote `""`
          if (i + 1 < source.length && source[i + 1] == '"') {
            buf.write('"');
            i += 2;
          } else {
            inQuotes = false;
            i++;
          }
        } else {
          buf.write(ch);
          i++;
        }
      } else {
        if (ch == '"') {
          inQuotes = true;
          i++;
        } else if (source.startsWith(sep, i)) {
          row.add(buf.toString());
          buf.clear();
          i += sep.length;
        } else if (ch == '\r') {
          row.add(buf.toString());
          buf.clear();
          rows.add(row);
          row = [];
          // Consume optional `\n`
          if (i + 1 < source.length && source[i + 1] == '\n') i++;
          i++;
        } else if (ch == '\n') {
          row.add(buf.toString());
          buf.clear();
          rows.add(row);
          row = [];
          i++;
        } else {
          buf.write(ch);
          i++;
        }
      }
    }

    // Flush last field/row
    if (buf.isNotEmpty || row.isNotEmpty) {
      row.add(buf.toString());
      rows.add(row);
    }

    return rows;
  }

  String _encodeField(String field, String sep) {
    final needsQuoting =
        field.contains(sep) ||
        field.contains('"') ||
        field.contains('\n') ||
        field.contains('\r');
    if (!needsQuoting) return field;
    final escaped = field.replaceAll('"', '""');
    return '"$escaped"';
  }

  Encoding _codecFor(CsvEncoding enc) {
    return switch (enc) {
      CsvEncoding.ascii => latin1,
      _ => utf8,
    };
  }

  double _scoreDelimiter(List<String> lines, String sep) {
    // Count occurrences per line (outside quotes)
    final counts = <int>[];
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      counts.add(_countOutsideQuotes(line, sep));
    }
    if (counts.isEmpty || counts.every((c) => c == 0)) return 0.0;

    // Prefer consistent counts across lines
    final mode = counts.fold<int>(0, (a, b) => a + b) ~/ counts.length;
    if (mode == 0) return 0.0;

    final consistent = counts.where((c) => c == mode).length / counts.length;
    // Normalise by expected columns to avoid favouring high-count delimiters
    return consistent * (1 - 1 / (mode + 1));
  }

  int _countOutsideQuotes(String line, String sep) {
    var count = 0;
    var inQ = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQ = !inQ;
      } else if (!inQ && line.startsWith(sep, i)) {
        count++;
        i += sep.length - 1;
      }
    }
    return count;
  }

  List<String> _splitLines(String text) {
    return text.split(RegExp(r'\r\n|\r|\n'));
  }
}
