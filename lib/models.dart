// Metro Widget IDF - modèles de données
// Créé par : Omar Pérez - 2026-11-09 08:10

class StopZone {
  final String id;
  final String name;
  final String type;
  final double x;
  final double y;
  double dist = 0;

  StopZone(this.id, this.name, this.type, this.x, this.y);

  Map<String, dynamic> toJson() => {
    'i': id,
    'n': name,
    't': type,
    'x': x,
    'y': y,
  };

  factory StopZone.fromJson(Map<String, dynamic> j) => StopZone(
    j['i'] as String,
    j['n'] as String,
    j['t'] as String,
    (j['x'] as num).toDouble(),
    (j['y'] as num).toDouble(),
  );
}

class LineInfo {
  final String id;
  final String short;
  final String mode;
  final String bg;
  final String fg;

  const LineInfo(this.id, this.short, this.mode, this.bg, this.fg);

  Map<String, dynamic> toJson() => {
    'i': id,
    's': short,
    'm': mode,
    'b': bg,
    'f': fg,
  };

  factory LineInfo.fromJson(Map<String, dynamic> j) => LineInfo(
    j['i'] as String,
    j['s'] as String,
    j['m'] as String,
    j['b'] as String,
    j['f'] as String,
  );
}

class Visit {
  final String lineId;
  final String destination;
  final DateTime time;

  const Visit(this.lineId, this.destination, this.time);
}

class BoardRow {
  final String line;
  final String mode;
  final String bg;
  final String fg;
  final String destination;
  final String stop;
  final List<DateTime> times;

  const BoardRow({
    required this.line,
    required this.mode,
    required this.bg,
    required this.fg,
    required this.destination,
    required this.stop,
    required this.times,
  });

  Map<String, dynamic> toJson() => {
    'line': line,
    'mode': mode,
    'bg': bg,
    'fg': fg,
    'dest': destination,
    'stop': stop,
    't': times.map((e) => e.millisecondsSinceEpoch).toList(),
  };

  factory BoardRow.fromJson(Map<String, dynamic> j) => BoardRow(
    line: j['line'] as String,
    mode: j['mode'] as String,
    bg: j['bg'] as String,
    fg: j['fg'] as String,
    destination: j['dest'] as String,
    stop: j['stop'] as String,
    times: (j['t'] as List)
        .map((e) => DateTime.fromMillisecondsSinceEpoch(e as int))
        .toList(),
  );
}

class Board {
  final String station;
  final int distance;
  final DateTime updated;
  final List<BoardRow> rows;
  final String? error;

  const Board({
    required this.station,
    required this.distance,
    required this.updated,
    required this.rows,
    this.error,
  });

  factory Board.failure(String msg) => Board(
    station: '—',
    distance: 0,
    updated: DateTime.now(),
    rows: const [],
    error: msg,
  );

  Map<String, dynamic> toJson() => {
    'station': station,
    'dist': distance,
    'updated': updated.millisecondsSinceEpoch,
    'rows': rows.map((e) => e.toJson()).toList(),
    'error': error,
  };

  factory Board.fromJson(Map<String, dynamic> j) => Board(
    station: j['station'] as String,
    distance: j['dist'] as int,
    updated: DateTime.fromMillisecondsSinceEpoch(j['updated'] as int),
    rows: (j['rows'] as List)
        .map((e) => BoardRow.fromJson(e as Map<String, dynamic>))
        .toList(),
    error: j['error'] as String?,
  );
}
