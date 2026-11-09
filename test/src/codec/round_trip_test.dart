import 'dart:convert';
import 'dart:typed_data';

import 'package:battle_protocol/battle_protocol.dart';
import 'package:test/test.dart';

import '../../helpers/message_samples.dart';
import '../../helpers/samples.dart';

void main() {
  const binary = BinaryProtocolCodec();
  const json = JsonProtocolCodec();
  final codecs = <String, ProtocolCodec<Object>>{
    'binary': binary,
    'json': json,
  };

  for (final MapEntry(key: name, value: codec) in codecs.entries) {
    group('$name codec', () {
      group('round-trips', () {
        for (final MapEntry(:key, :value) in sampleCommands.entries) {
          test('the command $key', () {
            expect(_command(codec, value), equals(value));
          });
        }
        for (final MapEntry(:key, :value) in sampleEvents.entries) {
          test('the event $key', () {
            expect(_event(codec, value), equals(value));
          });
        }
        for (final MapEntry(:key, :value) in sampleClientMessages.entries) {
          test('the client message $key', () {
            expect(_clientMessage(codec, value), equals(value));
          });
        }
        for (final MapEntry(:key, :value) in sampleHostMessages.entries) {
          test('the host message $key', () {
            expect(_hostMessage(codec, value), equals(value));
          });
        }
        for (final MapEntry(:key, :value) in sampleEntries.entries) {
          test('the log entry $key', () {
            expect(_entry(codec, value), equals(value));
          });
        }
      });

      test('AI-05 every command records its origin: player, AI or server '
          '(decisions 162, 166)', () {
        const order = Observe(unitId: 'u-scout-1');
        for (final origin in Origin.values) {
          final command = const Command(
            sender: Sender(accountId: 'a-1', sectionId: 's-1'),
            sentAt: Duration(seconds: 5),
            order: order,
          ).stamped(origin: origin, seq: 7);
          final decoded = _command(codec, command);
          expect(decoded.origin, equals(origin));
          expect(decoded.seq, equals(7));
        }
      });

      test('decision 183 a first-person shot carries its aim direction and '
          'fire time', () {
        final shot = FireAimed(
          unitId: 'u-1',
          aim: Direction.of(-0.000001, 0.999999, -0.25),
          fireTime: const Duration(days: 20, microseconds: 1),
        );
        final command = Command(
          sender: const Sender(accountId: 'a-1', sectionId: 's-1'),
          sentAt: const Duration(days: 20),
          order: shot,
        );
        expect(_command(codec, command).order, equals(shot));
      });

      test('keeps the extremes of the integer range', () {
        for (final amount in [0, -1, 4503599627370495, -4503599627370496]) {
          final command = Command(
            sender: const Sender(accountId: '', sectionId: 'é ✓ 🎯'),
            sentAt: Duration(microseconds: amount),
            order: TransferMoney(toSectionId: 's', amount: amount),
          );
          expect(_command(codec, command), equals(command));
        }
      });

      test('keeps doubles exactly', () {
        for (final hp in [0.1, 1 / 3, 1e-300, 1.7976931348623157e308, -0.0]) {
          final event = Repaired(targetId: 't', hp: hp);
          expect(_event(codec, event), equals(event));
        }
      });

      test('refuses to encode an integer outside the wire range', () {
        expect(
          () => codec.encodeCommand(
            const Command(
              sender: Sender(accountId: 'a', sectionId: 's'),
              sentAt: Duration.zero,
              order: TransferMoney(toSectionId: 's', amount: 4503599627370496),
            ),
          ),
          throwsArgumentError,
        );
        expect(
          () => codec.encodeEvent(
            const OrderRefused(seq: -4503599627370497, reason: 'r'),
          ),
          throwsArgumentError,
        );
      });

      test('refuses to encode a number that is not finite', () {
        expect(
          () =>
              codec.encodeEvent(const Repaired(targetId: 't', hp: double.nan)),
          throwsArgumentError,
        );
      });

      test('refuses to encode a cell outside the wire range', () {
        expect(
          () => codec.encodeEvent(
            const StructureBuilt(
              siteId: 's',
              structure: 'wall',
              cells: [Cell(0, 4503599627370496)],
            ),
          ),
          throwsArgumentError,
        );
      });
    });
  }

  group('BinaryProtocolCodec', () {
    test('a battle log round-trips', () {
      final entries = sampleEntries.values.toList();
      expect(binary.decodeLog(binary.encodeLog(entries)), equals(entries));
    });

    test('an empty battle log round-trips', () {
      expect(binary.decodeLog(binary.encodeLog(const [])), isEmpty);
    });

    test('a log is its header and one frame per entry, so entries can be '
        'appended one at a time', () {
      final entries = sampleEntries.values.toList();
      final appended = BytesBuilder()..add(binary.logHeader());
      for (final entry in entries) {
        appended.add(binary.logFrame(entry));
      }
      expect(appended.takeBytes(), equals(binary.encodeLog(entries)));
    });

    test('a battle log starts with BTLG and the version', () {
      expect(
        binary.logHeader(),
        equals([...ascii.encode('BTLG'), protocolVersion]),
      );
    });

    test('a single message starts with the version', () {
      final bytes = binary.encodeEvent(const UnitStored(unitId: 'u'));
      expect(bytes.first, equals(protocolVersion));
    });
  });

  group('JsonProtocolCodec', () {
    test('writes the version under v and the type under its name', () {
      final json = jsonDecode(
        const JsonProtocolCodec().encodeEvent(
          const Eliminated(team: 'red', loss: HqLoss.lostWithBridge),
        ),
      );
      expect(
        json,
        equals({
          'v': 1,
          'type': 'eliminated',
          'team': 'red',
          'loss': 'lost_with_bridge',
        }),
      );
    });

    test('reads a whole number where a double is expected', () {
      const text = '{"v":1,"type":"repaired","target":"t","hp":180}';
      expect(
        json.decodeEvent(text),
        equals(const Repaired(targetId: 't', hp: 180)),
      );
    });

    test('reads a null optional field as absent', () {
      const text =
          '{"v":1,"type":"relic_lost","relic":"r","previous_owner":null}';
      expect(json.decodeEvent(text), equals(const RelicLost(relicId: 'r')));
    });

    test('writes positions in metres and rounds them to the centimetre', () {
      const text =
          '{"v":1,"type":"unit_deployed","unit":"u","at":[1.234,2.5,-3.006]}';
      expect(
        json.decodeEvent(text),
        equals(const UnitDeployed(unitId: 'u', at: Position(123, 250, -301))),
      );
    });
  });
}

Command _command(ProtocolCodec<Object> codec, Command command) =>
    switch (codec) {
      BinaryProtocolCodec() => codec.decodeCommand(
        codec.encodeCommand(command),
      ),
      JsonProtocolCodec() => codec.decodeCommand(codec.encodeCommand(command)),
      _ => throw UnimplementedError(),
    };

BattleEvent _event(ProtocolCodec<Object> codec, BattleEvent event) =>
    switch (codec) {
      BinaryProtocolCodec() => codec.decodeEvent(codec.encodeEvent(event)),
      JsonProtocolCodec() => codec.decodeEvent(codec.encodeEvent(event)),
      _ => throw UnimplementedError(),
    };

LogEntry _entry(ProtocolCodec<Object> codec, LogEntry entry) => switch (codec) {
  BinaryProtocolCodec() => codec.decodeEntry(codec.encodeEntry(entry)),
  JsonProtocolCodec() => codec.decodeEntry(codec.encodeEntry(entry)),
  _ => throw UnimplementedError(),
};

ClientMessage _clientMessage(
  ProtocolCodec<Object> codec,
  ClientMessage message,
) => switch (codec) {
  BinaryProtocolCodec() => codec.decodeClientMessage(
    codec.encodeClientMessage(message),
  ),
  JsonProtocolCodec() => codec.decodeClientMessage(
    codec.encodeClientMessage(message),
  ),
  _ => throw UnimplementedError(),
};

HostMessage _hostMessage(ProtocolCodec<Object> codec, HostMessage message) =>
    switch (codec) {
      BinaryProtocolCodec() => codec.decodeHostMessage(
        codec.encodeHostMessage(message),
      ),
      JsonProtocolCodec() => codec.decodeHostMessage(
        codec.encodeHostMessage(message),
      ),
      _ => throw UnimplementedError(),
    };
