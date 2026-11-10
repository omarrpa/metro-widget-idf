// Metro Widget IDF - référentiels IDFM (zones d'arrêts, lignes) avec cache local
// Créé par : Omar Pérez - 2026-11-09 08:10
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'config.dart';
import 'models.dart';

class Referentials {
  static List<StopZone>? _zones;
  static Map<String, LineInfo>? _lines;

  static Future<List<StopZone>> zones() async {
    if (_zones != null) return _zones!;
    final raw = await _cached(
      'zones.json',
      () => _download('zones-d-arrets', [
        'zdaid',
        'zdaname',
        'zdatype',
        'zdaxepsg2154',
        'zdayepsg2154',
      ], _parseZones),
    );
    _zones = (raw as List)
        .map((e) => StopZone.fromJson(e as Map<String, dynamic>))
        .toList();
    return _zones!;
  }

  static Future<Map<String, LineInfo>> lines() async {
    if (_lines != null) return _lines!;
    final raw = await _cached(
      'lines.json',
      () => _download('referentiel-des-lignes', [
        'id_line',
        'shortname_line',
        'transportmode',
        'colourweb_hexa',
        'textcolourweb_hexa',
      ], _parseLines),
    );
    _lines = {
      for (final e in (raw as List).cast<Map<String, dynamic>>())
        e['i'] as String: LineInfo.fromJson(e),
    };
    return _lines!;
  }

  static Future<dynamic> _cached(
    String name,
    Future<List<Map<String, dynamic>>> Function() fetch,
  ) async {
    final dir = await getApplicationSupportDirectory();
    final f = File('${dir.path}/$name');
    final fresh =
        f.existsSync() &&
        DateTime.now().difference(f.lastModifiedSync()).inDays <
            AppConfig.refCacheDays;
    if (fresh) return jsonDecode(await f.readAsString());
    try {
      final data = await fetch();
      await f.writeAsString(jsonEncode(data));
      return data;
    } catch (_) {
      if (f.existsSync()) return jsonDecode(await f.readAsString());
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> _download(
    String dataset,
    List<String> fields,
    List<Map<String, dynamic>> Function(List<Map<String, String>>) parse,
  ) async {
    final base = '${AppConfig.odsBase}/$dataset/exports/csv';
    var r = await http
        .get(Uri.parse('$base?delimiter=%3B&select=${fields.join(',')}'))
        .timeout(const Duration(seconds: 60));
    if (r.statusCode != 200) {
      r = await http
          .get(Uri.parse('$base?delimiter=%3B'))
          .timeout(const Duration(seconds: 90));
    }
    if (r.statusCode != 200) {
      throw HttpException('Référentiel $dataset : HTTP ${r.statusCode}');
    }
    return parse(_csv(utf8.decode(r.bodyBytes)));
  }

  static List<Map<String, dynamic>> _parseZones(
    List<Map<String, String>> rows,
  ) {
    final out = <Map<String, dynamic>>[];
    for (final r in rows) {
      final x = _num(r['zdaxepsg2154']);
      final y = _num(r['zdayepsg2154']);
      final id = r['zdaid'] ?? '';
      if (x == null || y == null || id.isEmpty) continue;
      out.add(
        StopZone(id, r['zdaname'] ?? '', r['zdatype'] ?? '', x, y).toJson(),
      );
    }
    return out;
  }

  static List<Map<String, dynamic>> _parseLines(
    List<Map<String, String>> rows,
  ) => [
    for (final r in rows)
      if ((r['id_line'] ?? '').isNotEmpty)
        LineInfo(
          r['id_line']!,
          r['shortname_line'] ?? r['id_line']!,
          r['transportmode'] ?? '',
          _hex(r['colourweb_hexa'], '#5A5A5A'),
          _hex(r['textcolourweb_hexa'], '#FFFFFF'),
        ).toJson(),
  ];

  static double? _num(String? s) =>
      s == null ? null : double.tryParse(s.replaceAll(',', '.'));

  static String _hex(String? s, String def) {
    final v = (s ?? '').replaceAll('#', '').trim();
    return RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(v)
        ? '#${v.toUpperCase()}'
        : def;
  }

  static List<Map<String, String>> _csv(String text) {
    final rows = <List<String>>[];
    var row = <String>[];
    final cell = StringBuffer();
    var quoted = false;
    for (var i = 0; i < text.length; i++) {
      final c = text[i];
      if (quoted) {
        if (c == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            cell.write('"');
            i++;
          } else {
            quoted = false;
          }
        } else {
          cell.write(c);
        }
      } else if (c == '"') {
        quoted = true;
      } else if (c == ';') {
        row.add(cell.toString());
        cell.clear();
      } else if (c == '\n') {
        row.add(cell.toString().replaceAll('\r', ''));
        cell.clear();
        rows.add(row);
        row = <String>[];
      } else {
        cell.write(c);
      }
    }
    if (cell.isNotEmpty || row.isNotEmpty) {
      row.add(cell.toString());
      rows.add(row);
    }
    if (rows.isEmpty) return [];
    final head = rows.first
        .map((h) => h.replaceAll('﻿', '').trim().toLowerCase())
        .toList();
    return [
      for (final r in rows.skip(1))
        if (r.length >= head.length)
          {for (var k = 0; k < head.length; k++) head[k]: r[k].trim()},
    ];
  }
}
