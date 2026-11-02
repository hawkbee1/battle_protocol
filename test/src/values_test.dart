import 'package:battle_protocol/battle_protocol.dart';
import 'package:test/test.dart';

void main() {
  group('Position', () {
    test('rounds metres to the centimetre (stack decision 3)', () {
      final position = Position.metres(1234.565, -0.004, 42.5);
      expect(position, equals(const Position(123457, 0, 4250)));
      expect(position.x, equals(1234.57));
      expect(position.y, equals(0));
      expect(position.z, equals(42.5));
    });

    test('refuses a value that is not finite', () {
      expect(() => Position.metres(double.nan, 0, 0), throwsArgumentError);
      expect(() => Position.metres(0, double.infinity, 0), throwsArgumentError);
    });
  });

  group('Direction', () {
    test('rounds its components to the millionth', () {
      final direction = Direction.of(0.6, -0.8, 0.0000004);
      expect(direction, equals(const Direction(600000, -800000, 0)));
      expect(direction.x, equals(0.6));
      expect(direction.y, equals(-0.8));
      expect(direction.z, equals(0));
    });

    test('refuses a value that is not finite', () {
      expect(() => Direction.of(0, 0, double.nan), throwsArgumentError);
    });
  });

  group('Cell', () {
    test('is on the ground without an island', () {
      expect(const Cell(3, 4).island, isNull);
      expect(const Cell(3, 4), isNot(equals(const Cell(3, 4, island: 'sky'))));
    });
  });

  group('Command', () {
    test('has no origin or sequence number until the host stamps it', () {
      const command = Command(
        sender: Sender(accountId: 'a', sectionId: 's'),
        sentAt: Duration(seconds: 1),
        order: Reload(unitId: 'u'),
      );
      expect(command.origin, isNull);
      expect(command.seq, isNull);

      final stamped = command.stamped(origin: Origin.ai, seq: 12);
      expect(stamped.origin, equals(Origin.ai));
      expect(stamped.seq, equals(12));
      expect(stamped.sender, equals(command.sender));
      expect(stamped.sentAt, equals(command.sentAt));
      expect(stamped.order, equals(command.order));
    });
  });

  group('orders', () {
    test('of one unit share their unit ID', () {
      const UnitOrder order = Land(unitId: 'u-helicopter-1');
      expect(order.unitId, equals('u-helicopter-1'));
      expect(
        const Land(unitId: 'u'),
        isNot(equals(const TakeOff(unitId: 'u'))),
      );
    });

    test('without fields are equal', () {
      expect(const BuyGuildCamp(), equals(const BuyGuildCamp()));
      expect(const BuyGuildCamp().props, isEmpty);
    });
  });
}
