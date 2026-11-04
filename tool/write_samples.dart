// Adds the encodings of new samples to the committed fixtures of version 1
// of the format, `test/fixtures/v1/`. It never changes a sample already
// written: those freeze the format.
//
// Run from the package: dart run tool/write_samples.dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:battle_protocol/battle_protocol.dart';

import '../test/helpers/samples.dart';

const _binary = BinaryProtocolCodec();
const _json = JsonProtocolCodec();
const _dir = 'test/fixtures/v1';

void main() {
  Directory(_dir).createSync(recursive: true);
  _write(
    'commands',
    sampleCommands,
    _binary.encodeCommand,
    _json.encodeCommand,
  );
  _write('events', sampleEvents, _binary.encodeEvent, _json.encodeEvent);
  _write('entries', sampleEntries, _binary.encodeEntry, _json.encodeEntry);
  final log = File('$_dir/log.hex');
  if (!log.existsSync()) {
    log.writeAsStringSync(
      '${_hex(_binary.encodeLog(sampleEntries.values.toList()))}\n',
    );
    print('wrote ${log.path}');
  }
}

void _write<T>(
  String name,
  Map<String, T> samples,
  Uint8List Function(T) binary,
  String Function(T) json,
) {
  final hexFile = File('$_dir/$name.hex');
  final hex = <String, String>{
    if (hexFile.existsSync())
      for (final line in hexFile.readAsLinesSync())
        if (line.isNotEmpty) line.split(' ').first: line.split(' ').last,
  };
  final jsonFile = File('$_dir/$name.json');
  final values = <String, Object?>{
    if (jsonFile.existsSync())
      ...jsonDecode(jsonFile.readAsStringSync()) as Map<String, Object?>,
  };
  for (final MapEntry(:key, :value) in samples.entries) {
    hex.putIfAbsent(key, () => _hex(binary(value)));
    values.putIfAbsent(key, () => jsonDecode(json(value)));
  }
  hexFile.writeAsStringSync(
    hex.entries.map((e) => '${e.key} ${e.value}\n').join(),
  );
  jsonFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(values)}\n',
  );
  print('wrote ${hexFile.path} and ${jsonFile.path}');
}

String _hex(Uint8List bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
