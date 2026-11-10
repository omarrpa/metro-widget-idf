// Metro Widget IDF - position -> zones d'arrêt les plus proches -> tableau des 2 prochains passages
// Créé par : Omar Pérez - 2026-11-09 08:10
import 'dart:convert';
import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:home_widget/home_widget.dart';

import 'config.dart';
import 'geo.dart';
import 'models.dart';
import 'prim_client.dart';
import 'referentials.dart';

class BoardService {
  static Future<String> apiKey() async {
    if (AppConfig.primApiKey.isNotEmpty) return AppConfig.primApiKey;
    return (await HomeWidget.getWidgetData<String>('prim_key')) ?? '';
  }

  static Future<void> setApiKey(String k) =>
      HomeWidget.saveWidgetData<String>('prim_key', k.trim());

  static Future<(double, double)?> locate({bool background = false}) async {
    try {
      if (!background) {
        if (!await Geolocator.isLocationServiceEnabled()) {
          throw Exception('Localisation désactivée');
        }
        var p = await Geolocator.checkPermission();
        if (p == LocationPermission.denied) {
          p = await Geolocator.requestPermission();
        }
        if (p == LocationPermission.denied ||
            p == LocationPermission.deniedForever) {
          throw Exception('Permission de localisation refusée');
        }
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      await _savePos(pos.latitude, pos.longitude);
      return (pos.latitude, pos.longitude);
    } catch (e) {
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) return (last.latitude, last.longitude);
      } catch (_) {}
      final lat = double.tryParse(
        (await HomeWidget.getWidgetData<String>('last_lat')) ?? '',
      );
      final lon = double.tryParse(
        (await HomeWidget.getWidgetData<String>('last_lon')) ?? '',
      );
      if (lat != null && lon != null) return (lat, lon);
      if (!background) rethrow;
      return null;
    }
  }

  static Future<void> _savePos(double lat, double lon) async {
    await HomeWidget.saveWidgetData<String>('last_lat', '$lat');
    await HomeWidget.saveWidgetData<String>('last_lon', '$lon');
  }

  static List<StopZone> nearest(List<StopZone> zones, double lat, double lon) {
    final (x, y) = Lambert93.project(lat, lon);
    for (final z in zones) {
      z.dist = sqrt(pow(z.x - x, 2) + pow(z.y - y, 2));
    }
    final sorted = [...zones]..sort((a, b) => a.dist.compareTo(b.dist));
    final inRadius = sorted
        .where((z) => z.dist <= AppConfig.searchRadiusM)
        .toList();
    if (inRadius.isEmpty) return sorted.take(1).toList();

    final picked = <StopZone>[];
    final seenTypes = <String>{};
    for (final z in inRadius) {
      if (seenTypes.add(z.type)) picked.add(z);
    }
    for (final z in inRadius) {
      if (picked.length >= AppConfig.maxZones) break;
      if (!picked.contains(z)) picked.add(z);
    }
    picked.sort((a, b) => a.dist.compareTo(b.dist));
    return picked.take(AppConfig.maxZones).toList();
  }

  static Future<Board> build({bool background = false}) async {
    try {
      final key = await apiKey();
      if (key.isEmpty) return Board.failure('Clé API PRIM manquante');
      final pos = await locate(background: background);
      if (pos == null) return Board.failure('Position inconnue');

      final zones = nearest(await Referentials.zones(), pos.$1, pos.$2);
      final lines = await Referentials.lines();
      final prim = PrimClient(key);

      Object? lastError;
      Future<(StopZone, List<Visit>)> fetch(StopZone z) async {
        try {
          return (z, await prim.stopArea(z.id));
        } catch (e) {
          lastError = e;
          return (z, <Visit>[]);
        }
      }

      final results = await Future.wait(zones.map(fetch));
      if (lastError != null && results.every((r) => r.$2.isEmpty)) {
        throw lastError!;
      }

      final groups = <String, (StopZone, Visit, List<DateTime>)>{};
      for (final (z, visits) in results) {
        for (final v in visits) {
          final k = '${v.lineId}|${v.destination}';
          groups.putIfAbsent(k, () => (z, v, <DateTime>[])).$3.add(v.time);
        }
      }

      final rows = <BoardRow>[];
      for (final (z, v, times) in groups.values) {
        times.sort();
        final li =
            lines[v.lineId] ??
            LineInfo(v.lineId, '?', z.type, '#5A5A5A', '#FFFFFF');
        rows.add(
          BoardRow(
            line: li.short,
            mode: li.mode,
            bg: li.bg,
            fg: li.fg,
            destination: v.destination,
            stop: z.name,
            times: times.take(AppConfig.timesPerRow).toList(),
          ),
        );
      }
      rows.sort((a, b) => a.times.first.compareTo(b.times.first));

      final first = zones.first;
      return Board(
        station: first.name,
        distance: first.dist.round(),
        updated: DateTime.now(),
        rows: rows.take(AppConfig.maxRows).toList(),
        error: rows.isEmpty ? 'Aucun passage annoncé' : null,
      );
    } catch (e) {
      return Board.failure(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  static Future<Board> refreshAndPush({bool background = false}) async {
    final b = await build(background: background);
    if (b.error != null && b.rows.isEmpty && background) {
      final prev = await HomeWidget.getWidgetData<String>('board_json');
      if (prev != null) return Board.fromJson(jsonDecode(prev));
    }
    await HomeWidget.saveWidgetData<String>('board_json', jsonEncode(b));
    await HomeWidget.updateWidget(
      androidName: AppConfig.androidWidget,
      iOSName: AppConfig.iosWidget,
    );
    return b;
  }
}
