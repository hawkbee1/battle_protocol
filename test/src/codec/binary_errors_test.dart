import 'dart:typed_data';

import 'package:battle_protocol/battle_protocol.dart';
import 'package:test/test.dart';

Matcher _refused(String message) => throwsA(
  isA<ProtocolException>().having(
    (e) => e.message,
    'message',
    contains(message),
  ),
);

void main() {
  const codec = BinaryProtocolCodec();

  Uint8List bytes(List<int> values) => Uint8List.fromList(values);

  /// The encoding of [event] with its byte at [index] (from the end when
  /// negative) set to [value].
  Uint8List patched(BattleEvent event, int index, int value) {
    final encoded = codec.encodeEvent(event);
    encoded[index < 0 ? encoded.length + index : index] = value;
    return encoded;
  }

  test('ProtocolException tells what is wrong', () {
    expect(
      const ProtocolException('unknown field x').toString(),
      equals('ProtocolException: unknown field x'),
    );
  });

  group('BinaryProtocolCodec refuses', () {
    test('an empty input', () {
      expect(() => codec.decodeEvent(bytes([])), _refused('end of input'));
    });

    test('another version', () {
      expect(
        () => codec.decodeEvent(bytes([2, 0])),
        _refused('unsupported version 2'),
      );
    });

    test('bytes after the message', () {
      final encoded = codec.encodeEvent(const UnitStored(unitId: 'u'));
      expect(
        () => codec.decodeEvent(bytes([...encoded, 0])),
        _refused('1 bytes left'),
      );
    });

    test('a varint not in its shortest form', () {
      expect(
        () => codec.decodeEvent(bytes([0x81, 0x00, 0])),
        _refused('shortest form'),
      );
    });

    test('a varint longer than 8 bytes', () {
      expect(
        () => codec.decodeEvent(bytes(List.filled(9, 0xff))),
        _refused('longer than 8 bytes'),
      );
    });

    test('an integer above the wire range', () {
      expect(
        () => codec.decodeEvent(bytes([...List.filled(7, 0xff), 0x7f])),
        _refused('out of range'),
      );
    });

    test('a length beyond the end of input', () {
      expect(
        () => codec.decodeEvent(patched(const UnitStored(unitId: 'u'), -2, 5)),
        _refused('length beyond the end of input'),
      );
    });

    test('a list longer than the input', () {
      expect(
        () => codec.decodeEvent(
          patched(
            const BattleEnded(
              winner: 'w',
              kind: WinKind.lastHq,
              eliminated: [],
            ),
            -1,
            100,
          ),
        ),
        _refused('length beyond the end of input'),
      );
    });

    test('text that is not UTF-8', () {
      expect(
        () =>
            codec.decodeEvent(patched(const UnitStored(unitId: 'u'), -1, 0xff)),
        _refused('unit is not valid UTF-8'),
      );
    });

    test('a boolean other than 0 or 1', () {
      expect(
        () => codec.decodeEvent(
          patched(
            const Attacked(
              attackerId: 'a',
              sectionId: 's',
              weapon: 'rifle',
              hit: true,
              impacts: [],
            ),
            -2,
            2,
          ),
        ),
        _refused('hit is not a boolean'),
      );
    });

    test('an optional field marked other than 0 or 1', () {
      expect(
        () => codec.decodeEvent(patched(const RelicLost(relicId: 'r'), -1, 3)),
        _refused('previous_owner is not a boolean'),
      );
    });

    test('an enum index out of range', () {
      expect(
        () => codec.decodeEvent(
          patched(const Eliminated(team: 't', loss: HqLoss.destroyed), -1, 9),
        ),
        _refused('loss has no value 9'),
      );
    });

    test('a number that is not finite', () {
      final encoded = codec.encodeEvent(const Repaired(targetId: 't', hp: 1));
      ByteData.sublistView(
        encoded,
        encoded.length - 8,
      ).setFloat64(0, double.infinity, Endian.little);
      expect(() => codec.decodeEvent(encoded), _refused('hp is not a finite'));
    });

    test('a message cut short', () {
      final encoded = codec.encodeEvent(const Repaired(targetId: 't', hp: 1));
      expect(
        () => codec.decodeEvent(Uint8List.sublistView(encoded, 0, 10)),
        _refused('end of input'),
      );
    });
  });

  group('BinaryProtocolCodec.decodeLog refuses', () {
    const entry = LogEntry(
      at: Duration.zero,
      events: [UnitStored(unitId: 'u')],
    );

    test('a file that is not a battle log', () {
      expect(
        () => codec.decodeLog(bytes([0x42, 0x54, 0x4C, 0x48, 1])),
        _refused('not a battle log'),
      );
    });

    test('another version', () {
      expect(
        () => codec.decodeLog(bytes([0x42, 0x54, 0x4C, 0x47, 2])),
        _refused('unsupported version 2'),
      );
    });

    test('a frame cut short', () {
      final log = codec.encodeLog([entry]);
      expect(
        () => codec.decodeLog(Uint8List.sublistView(log, 0, log.length - 1)),
        _refused('end of input'),
      );
    });

    test('a frame longer than its entry', () {
      final frame = codec.logFrame(entry);
      frame[0] += 1;
      expect(
        () => codec.decodeLog(bytes([...codec.logHeader(), ...frame, 0])),
        _refused('1 bytes left'),
      );
    });
  });
}
