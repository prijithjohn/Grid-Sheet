import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:grid_sheet/data/serialization/serialization.dart';

void main() {
  group('Schema Version and Validation Tests', () {
    const serializer = WorkbookSerializer();

    test('accepts valid version 1 with schemaVersion key', () {
      final validJson = jsonEncode({
        'schemaVersion': 1,
        'workbook': {
          'id': 'wb_1',
          'title': 'Test.gsheet',
          'activeSheet': 0,
          'sheets': [
            {'id': 's_1', 'name': 'Sheet1', 'cells': []},
          ],
        },
      });

      final wb = serializer.decode(validJson);
      expect(wb.id, equals('wb_1'));
      expect(wb.title, equals('Test.gsheet'));
      expect(wb.sheetCount, equals(1));
    });

    test('accepts valid version 1 with fallback version key', () {
      final validJson = jsonEncode({
        'version': 1,
        'workbook': {
          'id': 'wb_legacy',
          'title': 'Legacy.gsheet',
          'activeSheet': 0,
          'sheets': [
            {'id': 's_1', 'name': 'Sheet1', 'cells': []},
          ],
        },
      });

      final wb = serializer.decode(validJson);
      expect(wb.id, equals('wb_legacy'));
    });

    test('rejects unsupported future schema version', () {
      final futureJson = jsonEncode({
        'schemaVersion': 2,
        'workbook': {
          'id': 'wb_future',
          'title': 'Future.gsheet',
          'sheets': [
            {'id': 's_1', 'name': 'Sheet1', 'cells': []},
          ],
        },
      });

      expect(
        () => serializer.decode(futureJson),
        throwsA(
          isA<WorkbookLoadException>().having(
            (e) => e.message,
            'message',
            contains('Unsupported file version 2'),
          ),
        ),
      );
    });

    test('rejects negative or 0 schema version', () {
      final zeroJson = jsonEncode({
        'schemaVersion': 0,
        'workbook': {'id': 'wb', 'sheets': []},
      });

      expect(
        () => serializer.decode(zeroJson),
        throwsA(
          isA<WorkbookLoadException>().having(
            (e) => e.message,
            'message',
            contains('Unsupported file version 0'),
          ),
        ),
      );
    });

    test('rejects missing or non-integer schema version', () {
      final missingVersion = jsonEncode({
        'workbook': {'id': 'wb'},
      });

      expect(
        () => serializer.decode(missingVersion),
        throwsA(
          isA<WorkbookLoadException>().having(
            (e) => e.message,
            'message',
            contains('Missing or invalid format version'),
          ),
        ),
      );

      final stringVersion = jsonEncode({
        'schemaVersion': 'v1',
        'workbook': {'id': 'wb'},
      });

      expect(
        () => serializer.decode(stringVersion),
        throwsA(
          isA<WorkbookLoadException>().having(
            (e) => e.message,
            'message',
            contains('Missing or invalid format version'),
          ),
        ),
      );
    });

    test('rejects invalid JSON syntax', () {
      const corrupt = '{ this is not valid json : 123 ]';

      expect(
        () => serializer.decode(corrupt),
        throwsA(
          isA<WorkbookLoadException>().having(
            (e) => e.message,
            'message',
            contains('File is not valid JSON'),
          ),
        ),
      );
    });

    test('rejects non-object root JSON', () {
      const arrayJson = '[1, 2, 3]';

      expect(
        () => serializer.decode(arrayJson),
        throwsA(
          isA<WorkbookLoadException>().having(
            (e) => e.message,
            'message',
            contains('Unexpected file structure'),
          ),
        ),
      );
    });

    test('rejects missing workbook data or empty sheets list', () {
      final noWb = jsonEncode({'schemaVersion': 1});
      expect(
        () => serializer.decode(noWb),
        throwsA(
          isA<WorkbookLoadException>().having(
            (e) => e.message,
            'message',
            contains('Missing workbook data'),
          ),
        ),
      );

      final emptySheets = jsonEncode({
        'schemaVersion': 1,
        'workbook': {'id': 'wb_1', 'sheets': []},
      });
      expect(
        () => serializer.decode(emptySheets),
        throwsA(
          isA<WorkbookLoadException>().having(
            (e) => e.message,
            'message',
            contains('Workbook must contain at least one sheet'),
          ),
        ),
      );
    });

    test('rejects missing required identifiers', () {
      final missingWbId = jsonEncode({
        'schemaVersion': 1,
        'workbook': {
          'sheets': [
            {'id': 's_1', 'name': 'Sheet1'},
          ],
        },
      });
      expect(
        () => serializer.decode(missingWbId),
        throwsA(
          isA<WorkbookLoadException>().having(
            (e) => e.message,
            'message',
            contains('Missing required field "id" in workbook.id'),
          ),
        ),
      );

      final missingSheetName = jsonEncode({
        'schemaVersion': 1,
        'workbook': {
          'id': 'wb_1',
          'sheets': [
            {'id': 's_1'},
          ],
        },
      });
      expect(
        () => serializer.decode(missingSheetName),
        throwsA(
          isA<WorkbookLoadException>().having(
            (e) => e.message,
            'message',
            contains('Missing required field "name" in sheet.name'),
          ),
        ),
      );
    });
  });
}
