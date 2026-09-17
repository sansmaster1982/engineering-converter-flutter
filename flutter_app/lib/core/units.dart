/// Unit conversion engine.
///
/// Every category keeps a list of units with a factor to the base unit.
/// Temperature is the only affine category and is handled separately.
library;

class Unit {
  const Unit(this.id, this.en, this.ru, this.toBase);

  /// Stable identifier used in storage and tests (never shown to the user).
  final String id;
  final String en;
  final String ru;

  /// Multiplier to the category base unit (ignored for temperature).
  final double toBase;

  String label(String lang) => lang == 'ru' ? ru : en;
}

class UnitCategory {
  const UnitCategory(this.id, this.units, {this.isTemperature = false});

  final String id;
  final List<Unit> units;
  final bool isTemperature;

  Unit unitById(String id) => units.firstWhere((u) => u.id == id);

  double convert(double value, Unit from, Unit to) {
    if (isTemperature) return convertTemperature(value, from.id, to.id);
    return value * from.toBase / to.toBase;
  }
}

double convertTemperature(double v, String from, String to) {
  double kelvin;
  switch (from) {
    case 'C':
      kelvin = v + 273.15;
    case 'F':
      kelvin = (v - 32) * 5 / 9 + 273.15;
    default:
      kelvin = v;
  }
  switch (to) {
    case 'C':
      return kelvin - 273.15;
    case 'F':
      return (kelvin - 273.15) * 9 / 5 + 32;
    default:
      return kelvin;
  }
}

const List<UnitCategory> categories = [
  UnitCategory('pressure', [
    Unit('Pa', 'Pa', 'Па', 1),
    Unit('kPa', 'kPa', 'кПа', 1000),
    Unit('MPa', 'MPa', 'МПа', 1e6),
    Unit('kgf_m2', 'kgf/m²', 'кгс/м²', 9.80665),
    Unit('kgf_cm2', 'kgf/cm²', 'кгс/см²', 98066.5),
    Unit('mmHg', 'mmHg', 'мм рт.ст.', 133.322),
    Unit('mmH2O', 'mmH₂O', 'мм вод.ст.', 9.80665),
    Unit('mH2O', 'mH₂O', 'м вод.ст.', 9806.65),
    Unit('bar', 'bar', 'бар', 100000),
    Unit('mbar', 'mbar', 'мбар', 100),
    Unit('atm', 'atm', 'атм', 101325),
    Unit('psi', 'psi', 'psi', 6894.757),
  ]),
  UnitCategory('flow', [
    Unit('m3_s', 'm³/s', 'м³/с', 1),
    Unit('m3_min', 'm³/min', 'м³/мин', 1 / 60),
    Unit('m3_h', 'm³/h', 'м³/ч', 1 / 3600),
    Unit('L_s', 'L/s', 'л/с', 0.001),
    Unit('L_min', 'L/min', 'л/мин', 0.001 / 60),
    Unit('L_h', 'L/h', 'л/ч', 0.001 / 3600),
    Unit('gpm', 'gpm (US)', 'гал/мин (US)', 0.003785411784 / 60),
    Unit('cfm', 'cfm', 'фут³/мин', 0.028316846592 / 60),
  ]),
  UnitCategory('power', [
    Unit('W', 'W', 'Вт', 1),
    Unit('kW', 'kW', 'кВт', 1000),
    Unit('MW', 'MW', 'МВт', 1e6),
    Unit('kcal_h', 'kcal/h', 'ккал/ч', 1.163),
    Unit('Mcal_h', 'Mcal/h', 'Мкал/ч', 1163),
    Unit('Gcal_h', 'Gcal/h', 'Гкал/ч', 1163000),
    Unit('BTU_h', 'BTU/h', 'BTU/ч', 0.29307107),
    Unit('ton_ref', 'ton (refr.)', 'т холода', 3516.853),
    Unit('hp', 'hp', 'л.с.', 735.49875),
  ]),
  UnitCategory('energy', [
    Unit('J', 'J', 'Дж', 1),
    Unit('kJ', 'kJ', 'кДж', 1000),
    Unit('MJ', 'MJ', 'МДж', 1e6),
    Unit('GJ', 'GJ', 'ГДж', 1e9),
    Unit('cal', 'cal', 'кал', 4.1868),
    Unit('kcal', 'kcal', 'ккал', 4186.8),
    Unit('Gcal', 'Gcal', 'Гкал', 4.1868e9),
    Unit('BTU', 'BTU', 'BTU', 1055.056),
    Unit('Wh', 'Wh', 'Вт·ч', 3600),
    Unit('kWh', 'kWh', 'кВт·ч', 3.6e6),
    Unit('MWh', 'MWh', 'МВт·ч', 3.6e9),
  ]),
  UnitCategory('temperature', [
    Unit('C', '°C', '°C', 1),
    Unit('F', '°F', '°F', 1),
    Unit('K', 'K', 'K', 1),
  ], isTemperature: true),
  UnitCategory('length', [
    Unit('mm', 'mm', 'мм', 0.001),
    Unit('cm', 'cm', 'см', 0.01),
    Unit('m', 'm', 'м', 1),
    Unit('km', 'km', 'км', 1000),
    Unit('in', 'in', 'дюйм', 0.0254),
    Unit('ft', 'ft', 'фут', 0.3048),
    Unit('yd', 'yd', 'ярд', 0.9144),
    Unit('mile', 'mile', 'миля', 1609.344),
  ]),
  UnitCategory('area', [
    Unit('mm2', 'mm²', 'мм²', 1e-6),
    Unit('cm2', 'cm²', 'см²', 1e-4),
    Unit('m2', 'm²', 'м²', 1),
    Unit('ha', 'ha', 'га', 1e4),
    Unit('km2', 'km²', 'км²', 1e6),
    Unit('in2', 'in²', 'дюйм²', 0.00064516),
    Unit('ft2', 'ft²', 'фут²', 0.09290304),
  ]),
  UnitCategory('volume', [
    Unit('mL', 'mL', 'мл', 1e-6),
    Unit('L', 'L', 'л', 0.001),
    Unit('m3', 'm³', 'м³', 1),
    Unit('cm3', 'cm³', 'см³', 1e-6),
    Unit('gal', 'gal (US)', 'галлон (US)', 0.003785411784),
    Unit('bbl', 'bbl', 'баррель', 0.158987295),
    Unit('ft3', 'ft³', 'фут³', 0.028316846592),
  ]),
  UnitCategory('mass', [
    Unit('g', 'g', 'г', 0.001),
    Unit('kg', 'kg', 'кг', 1),
    Unit('t', 't', 'т', 1000),
    Unit('lb', 'lb', 'фунт', 0.45359237),
    Unit('oz', 'oz', 'унция', 0.028349523),
  ]),
  UnitCategory('velocity', [
    Unit('m_s', 'm/s', 'м/с', 1),
    Unit('m_min', 'm/min', 'м/мин', 1 / 60),
    Unit('km_h', 'km/h', 'км/ч', 1 / 3.6),
    Unit('ft_s', 'ft/s', 'фут/с', 0.3048),
    Unit('ft_min', 'ft/min', 'фут/мин', 0.3048 / 60),
    Unit('mph', 'mph', 'миль/ч', 0.44704),
    Unit('knot', 'knot', 'узел', 0.514444),
  ]),
];

UnitCategory categoryById(String id) =>
    categories.firstWhere((c) => c.id == id, orElse: () => categories.first);
