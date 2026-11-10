import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:battle_protocol/battle_protocol.dart';
import 'package:test/test.dart';

import '../../helpers/message_samples.dart';
import '../../helpers/samples.dart';

/// The committed encodings of version 1 (`tool/write_samples.dart` adds
/// new samples and never changes these).
const _fixtures = 'test/fixtures/v1';

Map<String, Uint8List> _hexFile(String name) => {
  for (final line in File('$_fixtures/$name.hex').readAsLinesSync())
    if (line.isNotEmpty) line.split(' ').first: _bytes(line.split(' ').last),
};

Map<String, Object?> _jsonFile(String name) =>
    jsonDecode(File('$_fixtures/$name.json').readAsStringSync())
        as Map<String, Object?>;

Uint8List _bytes(String hex) => Uint8List.fromList([
  for (var i = 0; i < hex.length; i += 2)
    int.parse(hex.substring(i, i + 2), radix: 16),
]);

void main() {
  const binary = BinaryProtocolCodec();
  const json = JsonProtocolCodec();

  void freeze<T>(
    String file,
    Map<String, T> samples,
    Uint8List Function(T) encodeBinary,
    T Function(Uint8List) decodeBinary,
    String Function(T) encodeJson,
    T Function(String) decodeJson,
  ) {
    group('version 1 $file', () {
      final hex = _hexFile(file);
      final values = _jsonFile(file);

      test('have a committed sample for every sample, and no other', () {
        expect(hex.keys, unorderedEquals(samples.keys));
        expect(values.keys, unorderedEquals(samples.keys));
      });

      for (final MapEntry(:key, :value) in samples.entries) {
        test('$key encodes to its committed binary sample', () {
          expect(encodeBinary(value), equals(hex[key]));
        });
        test('$key decodes from its committed binary sample', () {
          expect(decodeBinary(hex[key]!), equals(value));
        });
        test('$key encodes to its committed JSON sample', () {
          expect(jsonDecode(encodeJson(value)), equals(values[key]));
        });
        test('$key decodes from its committed JSON sample', () {
          expect(decodeJson(jsonEncode(values[key])), equals(value));
        });
      }
    });
  }

  freeze(
    'commands',
    sampleCommands,
    binary.encodeCommand,
    binary.decodeCommand,
    json.encodeCommand,
    json.decodeCommand,
  );
  freeze(
    'events',
    sampleEvents,
    binary.encodeEvent,
    binary.decodeEvent,
    json.encodeEvent,
    json.decodeEvent,
  );
  freeze(
    'entries',
    sampleEntries,
    binary.encodeEntry,
    binary.decodeEntry,
    json.encodeEntry,
    json.decodeEntry,
  );

  freeze(
    'client_messages',
    sampleClientMessages,
    binary.encodeClientMessage,
    binary.decodeClientMessage,
    json.encodeClientMessage,
    json.decodeClientMessage,
  );
  freeze(
    'host_messages',
    sampleHostMessages,
    binary.encodeHostMessage,
    binary.decodeHostMessage,
    json.encodeHostMessage,
    json.decodeHostMessage,
  );

  group('version 1 battle log', () {
    final log = _bytes(File('$_fixtures/log.hex').readAsStringSync().trim());
    final entries = sampleEntries.values.toList();

    test('encodes to its committed sample', () {
      expect(binary.encodeLog(entries), equals(log));
    });

    test('decodes from its committed sample', () {
      expect(binary.decodeLog(log), equals(entries));
    });
  });

  group('the message samples', () {
    void coverEveryType(
      Iterable<Object> messages,
      String Function(Object) encode,
      Object Function(Uint8List) decode,
      int types,
    ) {
      final names = {
        for (final message in messages)
          (jsonDecode(encode(message)) as Map)['type'],
      };
      expect(names, hasLength(types));
      expect(
        () => decode(Uint8List.fromList([protocolVersion, types])),
        throwsA(
          isA<ProtocolException>().having(
            (e) => e.message,
            'message',
            contains('type has no value $types'),
          ),
        ),
      );
    }

    test('cover every client message type', () {
      coverEveryType(
        sampleClientMessages.values,
        (m) => json.encodeClientMessage(m as ClientMessage),
        binary.decodeClientMessage,
        4,
      );
    });

    test('cover every host message type', () {
      coverEveryType(
        sampleHostMessages.values,
        (m) => json.encodeHostMessage(m as HostMessage),
        binary.decodeHostMessage,
        9,
      );
    });
  });

  group('the samples', () {
    test('cover every order type, each under its JSON type', () {
      for (final MapEntry(:key, :value) in sampleOrders.entries) {
        final command = Command(
          sender: const Sender(accountId: 'a', sectionId: 's'),
          sentAt: Duration.zero,
          order: value,
        );
        final encoded = jsonDecode(json.encodeCommand(command)) as Map;
        expect((encoded['order'] as Map)['type'], equals(key));
      }
      // The binary tags run from 0: the one after the last sample is unknown.
      expect(
        () => binary.decodeCommand(
          Uint8List.fromList([
            protocolVersion,
            0, // no seq
            0, // no origin
            1, 0x61, 1, 0x62, // sender
            0, // sent at
            sampleOrders.length,
          ]),
        ),
        throwsA(
          isA<ProtocolException>().having(
            (e) => e.message,
            'message',
            contains('type has no value ${sampleOrders.length}'),
          ),
        ),
      );
    });

    test('cover every event type, each under its JSON type', () {
      for (final MapEntry(:key, :value) in sampleEvents.entries) {
        final encoded = jsonDecode(json.encodeEvent(value)) as Map;
        expect(encoded['type'], equals(key));
      }
      expect(
        () => binary.decodeEvent(
          Uint8List.fromList([protocolVersion, sampleEvents.length]),
        ),
        throwsA(
          isA<ProtocolException>().having(
            (e) => e.message,
            'message',
            contains('type has no value ${sampleEvents.length}'),
          ),
        ),
      );
    });
  });
}
