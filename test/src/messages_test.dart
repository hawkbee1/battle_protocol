import 'dart:convert';

import 'package:battle_protocol/battle_protocol.dart';
import 'package:test/test.dart';

import '../helpers/message_samples.dart';

void main() {
  const binary = BinaryProtocolCodec();
  const json = JsonProtocolCodec();

  Map<String, Object?> jsonOf(HostMessage message) =>
      jsonDecode(json.encodeHostMessage(message)) as Map<String, Object?>;

  HostMessage viaBinary(HostMessage message) =>
      binary.decodeHostMessage(binary.encodeHostMessage(message));

  group('the view of a section', () {
    late SectionView view;

    setUp(() => view = sampleHostMessages['section_view']! as SectionView);

    test('MAP-08 carries the whole delta layer, in order', () {
      final decoded = viaBinary(view) as SectionView;

      expect(decoded.world, equals(view.world));
      expect(decoded.world.map((e) => e.runtimeType), [
        StructureBuilt,
        ObjectDamaged,
        ObjectDestroyed,
        CraterDug,
      ]);
    });

    test('MAP-29 decision 21 a unit of another section, allied or not, '
        'carries no private state', () {
      final units = jsonOf(view)['units']! as List<Object?>;
      final others = [
        for (final unit in units.cast<Map<String, Object?>>())
          if (unit['section'] != 's-1c9e') unit,
      ];

      expect(others, isNotEmpty);
      for (final unit in others) {
        expect(unit, isNot(contains('private')));
      }
    });

    test('MAP-49 decision 232 carries the relics, its own HQ with its AP and '
        'an enemy HQ without', () {
      final decoded = viaBinary(view) as SectionView;

      expect(decoded.relics.map((r) => r.relicId), ['relic-3', 'relic-4']);
      expect(decoded.relics.last.owner, isNull);
      expect(decoded.hqs.first.ap, isNotNull);
      expect(decoded.hqs.last.ap, isNull);
    });

    test('RELIC-16 carries the victory countdown', () {
      final decoded = viaBinary(view) as SectionView;

      expect(
        decoded.hold,
        const HoldView(
          team: 'team-red',
          since: Duration(hours: 4),
          winsAt: Duration(hours: 28),
        ),
      );
    });

    test('stack decision 8 carries an AP pool with its rate, so the client '
        'computes AP between updates', () {
      final unit = (viaBinary(view) as SectionView).units.first;

      expect(unit.private!.ap.perHour, equals(1));
      expect(unit.private!.ap.at, equals(const Duration(hours: 5, seconds: 1)));
    });
  });

  group('the update of a tick', () {
    test('COMBAT-57 decision 234 a hit by an unseen shooter names the unit '
        'hit and the damage, not the shooter', () {
      final tick = sampleHostMessages['tick_unseen_hit']! as TickUpdate;
      final encoded = json.encodeHostMessage(tick);

      expect(viaBinary(tick), equals(tick));
      expect(encoded, isNot(contains('attacker')));
      expect(encoded, isNot(contains('u-enemy')));
      expect(encoded, isNot(contains('friendly')));
      expect((viaBinary(tick) as TickUpdate).unseenHits.single.damage, 12);
    });

    test('COMBAT-58 decision 237 a shot whose outcome the section does not '
        'see shows the shooter firing, with no target and no hit or miss', () {
      final tick = sampleHostMessages['tick_update']! as TickUpdate;
      final fired =
          (jsonOf(tick)['fired']! as List<Object?>).single!
              as Map<String, Object?>;

      expect(viaBinary(tick), equals(tick));
      expect(fired.keys, {'attacker', 'section', 'weapon', 'shots', 'impacts'});
      expect(fired, isNot(contains('hit')));
      expect(fired, isNot(contains('hits')));
    });

    test('stack decision 3 a unit that stands still sends nothing: an empty '
        'tick holds only its time', () {
      const tick = TickUpdate(at: Duration(seconds: 1));

      expect(viaBinary(tick), equals(tick));
      expect(binary.encodeHostMessage(tick), hasLength(lessThan(20)));
    });
  });

  group('alerts', () {
    test('RELIC-10 decision 233 an alert names the relic, its new owner and '
        'when it changed owner, for players who connect later', () {
      final alert = sampleHostMessages['relic_alert']! as RelicAlert;

      expect(viaBinary(alert), equals(alert));
      expect(jsonOf(alert), {
        'v': 1,
        'type': 'relic_alert',
        'at_us': const Duration(hours: 5, minutes: 12).inMicroseconds,
        'relic': 'relic-3',
        'team': 'team-blue',
      });
    });
  });

  group('client messages', () {
    test('AI-03 an AI agent signs in and sends commands with the same '
        'messages as a player: only its credential differs', () {
      final player = sampleClientMessages['sign_in']! as SignIn;
      final agent = sampleClientMessages['sign_in_api_key']! as SignIn;

      expect(player.kind, CredentialKind.jwt);
      expect(agent.kind, CredentialKind.apiKey);
      for (final message in [player, agent]) {
        expect(
          json.decodeClientMessage(json.encodeClientMessage(message)),
          equals(message),
        );
      }
    });

    test('AI-05 decision 162 a command a client sends carries no origin nor '
        'sequence number: the host sets them', () {
      final send = sampleClientMessages['send_command']! as SendCommand;
      final encoded =
          jsonDecode(json.encodeClientMessage(send)) as Map<String, Object?>;
      final command = encoded['command']! as Map<String, Object?>;

      expect(command, isNot(contains('origin')));
      expect(command, isNot(contains('seq')));
      expect(encoded['request'], 4096);
    });
  });

  group(SignIn, () {
    test('hides its credential when printed', () {
      const signIn = SignIn(
        battleId: 'b-1',
        kind: CredentialKind.apiKey,
        credential: 'btk_secret',
      );

      expect(signIn.toString(), isNot(contains('btk_secret')));
      expect(signIn.toString(), contains('b-1'));
    });
  });

  group('messages without fields', () {
    test('are equal and hash alike', () {
      expect(const ResyncRequest().hashCode, const ResyncRequest().hashCode);
      expect(const Heartbeat().hashCode, const Heartbeat().hashCode);
      expect(const Heartbeat(), isNot(equals(const ResyncRequest())));
    });
  });
}
