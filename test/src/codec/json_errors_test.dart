import 'dart:convert';

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
  const codec = JsonProtocolCodec();

  /// A valid command, as an AI agent sends it, with [changes] applied to
  /// its order.
  String command(Map<String, Object?> order) => jsonEncode({
    'v': 1,
    'sender': {'account': 'a', 'section': 's'},
    'sent_at_us': 0,
    'order': order,
  });

  String event(Map<String, Object?> fields) => jsonEncode({'v': 1, ...fields});

  group('JsonProtocolCodec reads', () {
    test('a command as an AI agent sends it, without seq or origin', () {
      expect(
        codec.decodeCommand(command({'type': 'store', 'unit': 'u'})),
        equals(
          const Command(
            sender: Sender(accountId: 'a', sectionId: 's'),
            sentAt: Duration.zero,
            order: Store(unitId: 'u'),
          ),
        ),
      );
    });
  });

  group('JsonProtocolCodec refuses', () {
    test('text that is not JSON', () {
      expect(() => codec.decodeEvent('{'), _refused('not JSON'));
    });

    test('JSON that is not an object', () {
      expect(() => codec.decodeEvent('[]'), _refused('not a JSON object'));
    });

    test('a message without a version', () {
      expect(() => codec.decodeEvent('{}'), _refused('missing field v'));
    });

    test('another version', () {
      expect(
        () => codec.decodeEvent('{"v":2}'),
        _refused('unsupported version 2'),
      );
    });

    test('a missing field', () {
      expect(
        () => codec.decodeEvent(event({'type': 'unit_stored'})),
        _refused('missing field unit'),
      );
    });

    test('a field the message does not have', () {
      expect(
        () => codec.decodeEvent(
          event({'type': 'unit_stored', 'unit': 'u', 'hp': 3}),
        ),
        _refused('unknown field hp'),
      );
    });

    test('a field a nested message does not have, with its path', () {
      expect(
        () => codec.decodeCommand(
          command({'type': 'store', 'unit': 'u', 'path': null, 'x': 1}),
        ),
        _refused('unknown field order.path'),
      );
    });

    test('an unknown type', () {
      expect(
        () => codec.decodeEvent(event({'type': 'teleported'})),
        _refused('type is not one of order_refused'),
      );
    });

    test('an unknown enum value', () {
      expect(
        () => codec.decodeEvent(
          event({'type': 'eliminated', 'team': 't', 'loss': 'surrender'}),
        ),
        _refused('loss is not one of destroyed, lost_with_bridge'),
      );
    });

    group('a value of the wrong kind:', () {
      final cases = <String, (String, Map<String, Object?>)>{
        'an integer as a string': (
          'seq is not an integer',
          {'type': 'order_refused', 'seq': '1', 'reason': 'r'},
        ),
        'a fractional integer': (
          'seq is not an integer',
          {'type': 'order_refused', 'seq': 1.5, 'reason': 'r'},
        ),
        'an integer out of the wire range': (
          'seq is not an integer in range',
          {'type': 'order_refused', 'seq': 9007199254740991, 'reason': 'r'},
        ),
        'a number as a string': (
          'hp is not a number',
          {'type': 'repaired', 'target': 't', 'hp': '3'},
        ),
        'a string as a number': (
          'unit is not a string',
          {'type': 'unit_stored', 'unit': 3},
        ),
        'a boolean as a number': (
          'hit is not a boolean',
          {
            'type': 'attacked',
            'attacker': 'a',
            'section': 's',
            'weapon': 'w',
            'hit': 1,
            'impacts': <Object>[],
          },
        ),
        'a position that is not a list': (
          'at is not a list',
          {'type': 'unit_deployed', 'unit': 'u', 'at': 'here'},
        ),
        'a position of two numbers': (
          'at is not a list of 3 numbers',
          {
            'type': 'unit_deployed',
            'unit': 'u',
            'at': [1, 2],
          },
        ),
        'a position with a string': (
          'at is not a number',
          {
            'type': 'unit_deployed',
            'unit': 'u',
            'at': [1, 2, 'z'],
          },
        ),
        'a position out of range': (
          'at is not a number in range',
          {
            'type': 'unit_deployed',
            'unit': 'u',
            'at': [1e20, 2, 3],
          },
        ),
        'a cell of one number': (
          'cells is not a cell',
          {
            'type': 'structure_built',
            'site': 's',
            'structure': 'wall',
            'cells': [
              [1],
            ],
          },
        ),
        'a cell with a numeric island': (
          'cells is not a cell',
          {
            'type': 'structure_built',
            'site': 's',
            'structure': 'wall',
            'cells': [
              [1, 2, 3],
            ],
          },
        ),
        'a cell with a fractional column': (
          'cells is not an integer',
          {
            'type': 'structure_built',
            'site': 's',
            'structure': 'wall',
            'cells': [
              [1.5, 2],
            ],
          },
        ),
        'a list of strings with a number': (
          'eliminated is not a list of strings',
          {
            'type': 'battle_ended',
            'winner': 'w',
            'kind': 'relics',
            'eliminated': ['a', 1],
          },
        ),
        'a nested list that is not a list': (
          'impacts is not a list',
          {
            'type': 'attacked',
            'attacker': 'a',
            'section': 's',
            'weapon': 'w',
            'hit': true,
            'impacts': 'none',
          },
        ),
        'a nested message that is not an object': (
          'impacts is not an object',
          {
            'type': 'attacked',
            'attacker': 'a',
            'section': 's',
            'weapon': 'w',
            'hit': true,
            'impacts': [1],
          },
        ),
      };
      for (final MapEntry(key: name, value: (message, fields))
          in cases.entries) {
        test(name, () {
          expect(() => codec.decodeEvent(event(fields)), _refused(message));
        });
      }

      test('a direction that is not a list', () {
        expect(
          () => codec.decodeCommand(
            command({
              'type': 'fire_aimed',
              'unit': 'u',
              'aim': 1,
              'fire_time_us': 0,
            }),
          ),
          _refused('order.aim is not a list'),
        );
      });

      test('a sender that is not an object', () {
        expect(
          () => codec.decodeCommand(
            jsonEncode({
              'v': 1,
              'sender': 'me',
              'sent_at_us': 0,
              'order': {'type': 'store', 'unit': 'u'},
            }),
          ),
          _refused('sender is not an object'),
        );
      });
    });
  });
}
