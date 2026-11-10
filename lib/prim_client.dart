// Metro Widget IDF - client API PRIM "Prochains passages - requête unitaire" (SIRI Lite)
// Créé par : Omar Pérez - 2026-11-09 08:10
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';
import 'models.dart';

class PrimClient {
  final String apiKey;
  PrimClient(this.apiKey);

  static final _lineRe = RegExp(r'C\d{5}');

  Future<List<Visit>> stopArea(String zdaId) async {
    final uri = Uri.parse(
      '${AppConfig.primBase}/stop-monitoring',
    ).replace(queryParameters: {'MonitoringRef': 'STIF:StopArea:SP:$zdaId:'});
    final r = await http
        .get(uri, headers: {'apikey': apiKey, 'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));
    if (r.statusCode == 401 || r.statusCode == 403) {
      throw Exception('Clé PRIM refusée (HTTP ${r.statusCode})');
    }
    if (r.statusCode != 200) throw Exception('PRIM HTTP ${r.statusCode}');

    final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    final deliveries =
        (j['Siri']?['ServiceDelivery']?['StopMonitoringDelivery'] as List?) ??
        const [];
    final now = DateTime.now().subtract(const Duration(seconds: 30));
    final out = <Visit>[];
    for (final d in deliveries) {
      for (final v in (d['MonitoredStopVisit'] as List?) ?? const []) {
        final mvj = v['MonitoredVehicleJourney'] as Map<String, dynamic>?;
        if (mvj == null) continue;
        final call = (mvj['MonitoredCall'] as Map<String, dynamic>?) ?? {};
        final status = '${call['DepartureStatus'] ?? ''}'.toLowerCase();
        if (status == 'cancelled') continue;
        final ts = _txt(
          call['ExpectedDepartureTime'] ??
              call['ExpectedArrivalTime'] ??
              call['AimedDepartureTime'] ??
              call['AimedArrivalTime'],
        );
        final t = DateTime.tryParse(ts)?.toLocal();
        if (t == null || t.isBefore(now)) continue;
        final line = _lineRe.firstMatch(_txt(mvj['LineRef']))?.group(0) ?? '';
        final dest = _txt(
          call['DestinationDisplay'] ??
              mvj['DestinationName'] ??
              mvj['DirectionName'],
        );
        out.add(Visit(line, dest.isEmpty ? '—' : dest, t));
      }
    }
    return out;
  }

  static String _txt(dynamic x) {
    if (x == null) return '';
    if (x is String) return x;
    if (x is List) return x.isEmpty ? '' : _txt(x.first);
    if (x is Map) return _txt(x['value']);
    return '$x';
  }
}
