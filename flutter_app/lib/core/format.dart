/// Number parsing and formatting shared by all screens.
library;

/// Parses user input. Accepts "1,5", "1.5", " 1 500 ", "1e-3", "-40".
/// Returns null for empty or invalid text.
double? parseNumber(String text) {
  var s = text.trim().replaceAll(' ', '').replaceAll(' ', '');
  if (s.isEmpty) return null;
  s = s.replaceAll(',', '.');
  if (s == '-' || s == '.' || s == '-.') return null;
  final v = double.tryParse(s);
  if (v == null || v.isNaN || v.isInfinite) return null;
  return v;
}

/// Human-friendly number formatting for engineering values.
///
/// * up to [significant] significant digits, trailing zeros removed
/// * plain notation between [sciBelow] and 1e12, scientific outside
/// * optional thousands grouping with a thin space
String formatNumber(
  double v, {
  int significant = 6,
  bool group = true,
  String decimal = '.',
  double sciBelow = 1e-4,
}) {
  if (v.isNaN) return '—';
  if (v.isInfinite) return v.isNegative ? '-∞' : '∞';
  if (v == 0) return '0';
  final abs = v.abs();
  String out;
  if (abs >= 1e12 || abs < sciBelow) {
    out = v.toStringAsExponential(significant - 1);
    // trim zeros in mantissa: 2.000000e+15 -> 2e+15
    final parts = out.split('e');
    var mant = parts[0];
    if (mant.contains('.')) {
      mant = mant.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    out = '${mant}e${parts[1]}';
  } else {
    // number of digits before the decimal point
    final intDigits = abs >= 1 ? abs.floor().toString().length : 0;
    var decimals = significant - intDigits;
    if (abs < 1) {
      // exponent of the leading digit, e.g. 0.00123 -> -3
      final exp = int.parse(abs.toStringAsExponential().split('e').last);
      decimals = significant - 1 - exp;
    }
    if (decimals < 0) decimals = 0;
    if (decimals > 12) decimals = 12;
    out = v.toStringAsFixed(decimals);
    if (out.contains('.')) {
      out = out.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    if (out == '-0') out = '0';
    if (group) out = _groupThousands(out);
  }
  if (decimal != '.') out = out.replaceAll('.', decimal);
  return out;
}

String _groupThousands(String s) {
  final neg = s.startsWith('-');
  if (neg) s = s.substring(1);
  final dot = s.indexOf('.');
  final intPart = dot >= 0 ? s.substring(0, dot) : s;
  final frac = dot >= 0 ? s.substring(dot) : '';
  if (intPart.length <= 4) return (neg ? '-' : '') + intPart + frac;
  final buf = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(' ');
    buf.write(intPart[i]);
  }
  return (neg ? '-' : '') + buf.toString() + frac;
}

/// Plain machine-friendly text (no grouping) suitable for putting back into an input.
String formatForInput(double v) =>
    formatNumber(v, significant: 10, group: false, sciBelow: 1e-9);
