// Prints the encoded sizes of the messages that stack decision 3's traffic
// estimate counts (M6 Issue 2), from the committed samples.
//
// Run from the package: dart run tool/message_sizes.dart
// ignore_for_file: avoid_print

import 'package:battle_protocol/battle_protocol.dart';

import '../test/helpers/message_samples.dart';

const _binary = BinaryProtocolCodec();
const _json = JsonProtocolCodec();

void main() {
  int size(String key) =>
      _binary.encodeHostMessage(sampleHostMessages[key]!).length;
  final empty = _binary
      .encodeHostMessage(const TickUpdate(at: Duration(hours: 5)))
      .length;
  final shot = sampleHostMessages['tick_rifle_shot']! as TickUpdate;
  for (final (name, bytes) in [
    ('empty tick', empty),
    ('tick, one moving unit', size('tick_one_moving_unit')),
    ('tick, ten moving vehicles', size('tick_ten_moving_vehicles')),
    ('tick, a rifle shot (one Attacked, one impact)', size('tick_rifle_shot')),
    (
      'the rifle shot event alone',
      _binary.encodeEvent(shot.events.single).length,
    ),
    ('tick, a hit by an unseen shooter', size('tick_unseen_hit')),
    ('tick, the weather changed', size('tick_weather_changed')),
    ('whole view, 16 units, 8 relics', size('section_view_16_units')),
    (
      'sign-in (JWT)',
      _binary.encodeClientMessage(sampleClientMessages['sign_in']!).length,
    ),
    (
      'command request (move)',
      _binary.encodeClientMessage(sampleClientMessages['send_command']!).length,
    ),
    ('command accepted', size('command_accepted')),
    ('roster, 3 unit types and 3 weapons', size('roster')),
  ]) {
    print('$name: $bytes bytes');
  }
  final view = sampleHostMessages['section_view_16_units']!;
  print(
    'whole view, 16 units, JSON: '
    '${_json.encodeHostMessage(view).length} bytes',
  );
}
