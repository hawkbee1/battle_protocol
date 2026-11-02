import 'dart:math';

import 'package:battle_protocol/battle_protocol.dart';
import 'package:test/test.dart';

void main() {
  group('ApiKey', () {
    final format = RegExp(r'^btk_[A-Za-z0-9_-]{43}$');

    test('AI-04 a generated key is 256 random bits after btk_', () {
      final key = ApiKey.generate(Random(1));
      expect(key.value, matches(format));
      expect(ApiKey.parse(key.value).value, equals(key.value));
    });

    test('two keys from a secure random differ', () {
      final random = Random.secure();
      expect(
        ApiKey.generate(random).value,
        isNot(equals(ApiKey.generate(random).value)),
      );
    });

    test('is stored as the SHA-256 of its value, in hexadecimal', () {
      final key = ApiKey.parse('btk_${'A' * 43}');
      expect(
        key.hash,
        equals(
          '5cd8bdce98cae44e932bcf6b0fc41aac'
          '2afa9de3d1e111f8f1db498ba2669610',
        ),
      );
    });

    test('refuses text that is not a key, without repeating it', () {
      for (final text in [
        '',
        'btk_${'A' * 42}',
        'btk_${'A' * 44}',
        'abc_${'A' * 43}',
        'btk_${'A' * 42}=',
        'btk_${'A' * 42}\n',
      ]) {
        expect(
          () => ApiKey.parse(text),
          throwsA(
            isA<FormatException>().having(
              (e) => e.toString(),
              'message',
              allOf(contains('not an API key'), isNot(contains('AAAA'))),
            ),
          ),
        );
      }
    });

    test('never shows its value in toString', () {
      final key = ApiKey.parse('btk_${'B' * 43}');
      expect(key.toString(), isNot(contains('BBBB')));
    });
  });
}
