// Metro Widget IDF - projection WGS84 -> Lambert 93 (EPSG:2154), validée contre pyproj
// Créé par : Omar Pérez - 2026-11-09 08:10
import 'dart:math';

class Lambert93 {
  static const _a = 6378137.0;
  static const _e = 0.0818191910428158;
  static const _x0 = 700000.0;
  static const _y0 = 6600000.0;
  static final _l0 = _rad(3);
  static final _p1 = _rad(44);
  static final _p2 = _rad(49);
  static final _p0 = _rad(46.5);

  static double _rad(double d) => d * pi / 180;
  static double _m(double p) => cos(p) / sqrt(1 - pow(_e * sin(p), 2));
  static double _t(double p) =>
      tan(pi / 4 - p / 2) /
      pow((1 - _e * sin(p)) / (1 + _e * sin(p)), _e / 2);

  static final _n =
      (log(_m(_p1)) - log(_m(_p2))) / (log(_t(_p1)) - log(_t(_p2)));
  static final _f = _m(_p1) / (_n * pow(_t(_p1), _n));
  static final _rho0 = _a * _f * pow(_t(_p0), _n);

  static (double, double) project(double lat, double lon) {
    final rho = _a * _f * pow(_t(_rad(lat)), _n);
    final th = _n * (_rad(lon) - _l0);
    return (_x0 + rho * sin(th), _y0 + _rho0 - rho * cos(th));
  }
}
