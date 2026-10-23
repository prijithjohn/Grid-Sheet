import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib/domain/ has zero dependencies on Flutter UI framework', () {
    final domainDir = Directory('lib/domain');
    expect(domainDir.existsSync(), isTrue, reason: 'lib/domain must exist');

    final dartFiles = domainDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    expect(
      dartFiles,
      isNotEmpty,
      reason: 'lib/domain must contain Dart source files',
    );

    final violatingFiles = <String>[];

    for (final file in dartFiles) {
      final lines = file.readAsLinesSync();
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('import ') &&
            trimmed.contains('package:flutter/')) {
          violatingFiles.add('${file.path}: $trimmed');
        }
      }
    }

    expect(
      violatingFiles,
      isEmpty,
      reason:
          'Domain model must be pure Dart with zero Flutter framework dependencies. '
          'Violations found:\n${violatingFiles.join('\n')}',
    );
  });
}
