import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Both languages must always be complete (vault: UX/Bilingual ID-EN).
void main() {
  Map<String, dynamic> arb(String locale) =>
      jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync()) as Map<String, dynamic>;

  Set<String> messages(Map<String, dynamic> file) => file.keys.where((k) => !k.startsWith('@')).toSet();

  final id = arb('id');
  final en = arb('en');

  test('Indonesian and English have exactly the same messages', () {
    expect(messages(en).difference(messages(id)), isEmpty, reason: 'only in English');
    expect(messages(id).difference(messages(en)), isEmpty, reason: 'only in Indonesian');
  });

  test('no message is left empty', () {
    for (final file in [id, en]) {
      for (final key in messages(file)) {
        expect((file[key] as String).trim(), isNotEmpty, reason: key);
      }
    }
  });

  test('placeholders match between the two languages', () {
    final placeholder = RegExp(r'\{(\w+)[,}]');
    for (final key in messages(id)) {
      final inId = placeholder.allMatches(id[key] as String).map((m) => m.group(1)).toSet();
      final inEn = placeholder.allMatches(en[key] as String).map((m) => m.group(1)).toSet();
      expect(inEn, inId, reason: key);
    }
  });
}
