/// Engineering calculations (pure functions, no Flutter imports).
library;

import 'dart:math' as math;

// ---------------------------------------------------------------------------
// Fluid properties
// ---------------------------------------------------------------------------

/// Specific heat of water, kJ/(kg·K), by temperature °C.
const Map<int, double> waterSpecificHeat = {
  0: 4.218,
  10: 4.192,
  20: 4.182,
  30: 4.178,
  40: 4.178,
  50: 4.180,
  60: 4.184,
  70: 4.189,
  80: 4.196,
  90: 4.204,
  100: 4.216,
};

/// Density of water, kg/m³, by temperature °C.
const Map<int, double> waterDensity = {
  0: 999.8,
  10: 999.7,
  20: 998.2,
  30: 995.7,
  40: 992.2,
  50: 988.0,
  60: 983.2,
  70: 977.8,
  80: 971.8,
  90: 965.3,
  100: 958.4,
};

/// Volumetric expansion coefficient of water, 1/K, by temperature °C.
const Map<int, double> waterAlpha = {
  0: 0.000013,
  10: 0.000088,
  20: 0.000207,
  30: 0.000303,
  40: 0.000385,
  50: 0.000457,
  60: 0.000523,
  70: 0.000582,
  80: 0.000640,
  90: 0.000696,
  100: 0.000752,
};

enum Fluid { water, ethyleneGlycol, propyleneGlycol }

/// (density kg/m³, specific heat kJ/(kg·K)) by glycol concentration, %.
const Map<Fluid, Map<int, (double, double)>> glycolData = {
  Fluid.ethyleneGlycol: {
    10: (1015, 3.9),
    20: (1030, 3.7),
    30: (1045, 3.5),
    40: (1060, 3.3),
    50: (1075, 3.1),
    60: (1090, 2.9),
  },
  Fluid.propyleneGlycol: {
    10: (1010, 3.8),
    20: (1020, 3.6),
    30: (1030, 3.4),
    40: (1040, 3.2),
    50: (1050, 3.0),
    60: (1060, 2.8),
  },
};

const List<int> glycolConcentrations = [10, 20, 30, 40, 50, 60];

/// Linear interpolation over a temperature table, clamped at the ends.
double interpolate(Map<int, double> table, double t) {
  final temps = table.keys.toList()..sort();
  if (t <= temps.first) return table[temps.first]!;
  if (t >= temps.last) return table[temps.last]!;
  for (var i = 0; i < temps.length - 1; i++) {
    final t1 = temps[i], t2 = temps[i + 1];
    if (t >= t1 && t <= t2) {
      final v1 = table[t1]!, v2 = table[t2]!;
      return v1 + (v2 - v1) * (t - t1) / (t2 - t1);
    }
  }
  return table[temps.first]!;
}

/// Returns (density kg/m³, specific heat kJ/(kg·K)).
(double rho, double cp) fluidProperties(
  Fluid fluid,
  int concentration,
  double avgTemp,
) {
  if (fluid == Fluid.water) {
    return (
      interpolate(waterDensity, avgTemp),
      interpolate(waterSpecificHeat, avgTemp),
    );
  }
  final table = glycolData[fluid]!;
  final entry = table[concentration] ?? table[30]!;
  return (entry.$1, entry.$2);
}

// ---------------------------------------------------------------------------
// Pipes
// ---------------------------------------------------------------------------

class PipeSize {
  const PipeSize(this.nominal, this.outer, this.wall);

  /// DN for steel; nominal outer diameter for plastic and copper.
  final int nominal;
  final double outer;
  final double wall;

  double get inner => outer - 2 * wall;
}

enum PipeMaterial { steel, ppr, pex, copper }

const Map<PipeMaterial, List<PipeSize>> pipeDatabase = {
  // GOST 3262 water-gas steel pipes (DN, OD, wall)
  PipeMaterial.steel: [
    PipeSize(15, 21.3, 2.8),
    PipeSize(20, 26.8, 2.8),
    PipeSize(25, 33.5, 3.2),
    PipeSize(32, 42.3, 3.2),
    PipeSize(40, 48.0, 3.5),
    PipeSize(50, 60.0, 3.5),
    PipeSize(65, 75.5, 4.0),
    PipeSize(80, 88.5, 4.0),
    PipeSize(100, 114.0, 4.5),
    PipeSize(125, 140.0, 4.5),
    PipeSize(150, 165.0, 4.5),
    PipeSize(200, 219.0, 6.0),
    PipeSize(250, 273.0, 7.0),
    PipeSize(300, 325.0, 8.0),
    PipeSize(350, 377.0, 9.0),
  ],
  // PP-R PN20 (SDR 6): OD × wall
  PipeMaterial.ppr: [
    PipeSize(20, 20, 3.4),
    PipeSize(25, 25, 4.2),
    PipeSize(32, 32, 5.4),
    PipeSize(40, 40, 6.7),
    PipeSize(50, 50, 8.3),
    PipeSize(63, 63, 10.5),
    PipeSize(75, 75, 12.5),
    PipeSize(90, 90, 15.0),
    PipeSize(110, 110, 18.3),
  ],
  // PEX / PE-RT: OD × wall
  PipeMaterial.pex: [
    PipeSize(16, 16, 2.0),
    PipeSize(20, 20, 2.0),
    PipeSize(25, 25, 2.3),
    PipeSize(32, 32, 2.9),
    PipeSize(40, 40, 3.7),
    PipeSize(50, 50, 4.6),
    PipeSize(63, 63, 5.8),
  ],
  // Copper EN 1057: OD × wall
  PipeMaterial.copper: [
    PipeSize(12, 12, 1.0),
    PipeSize(15, 15, 1.0),
    PipeSize(18, 18, 1.0),
    PipeSize(22, 22, 1.0),
    PipeSize(28, 28, 1.5),
    PipeSize(35, 35, 1.5),
    PipeSize(42, 42, 1.5),
    PipeSize(54, 54, 2.0),
  ],
};

/// Flow velocity in a pipe, m/s. [flowM3h] in m³/h, [innerMm] in mm.
double pipeVelocity(double flowM3h, double innerMm) {
  if (innerMm <= 0) throw ArgumentError('inner diameter must be positive');
  final area = math.pi * math.pow(innerMm / 2000, 2);
  return flowM3h / 3600 / area;
}

/// Flow (m³/h) that gives [velocity] m/s in a pipe with [innerMm] inner diameter.
double pipeFlowForVelocity(double velocity, double innerMm) {
  final area = math.pi * math.pow(innerMm / 2000, 2);
  return velocity * area * 3600;
}

enum VelocityRating { low, ok, high }

/// Rough assessment against common HVAC practice (0.3 … 2.0 m/s for closed loops).
VelocityRating rateVelocity(double v) {
  if (v < 0.3) return VelocityRating.low;
  if (v > 2.0) return VelocityRating.high;
  return VelocityRating.ok;
}

// ---------------------------------------------------------------------------
// Thermal power
// ---------------------------------------------------------------------------

/// Heat output, kW, from volumetric flow (m³/h), fluid properties and ΔT (K).
double thermalPowerKw(double flowM3h, double rho, double cp, double dT) =>
    flowM3h * rho * cp * dT / 3600;

/// Volumetric flow, m³/h, that carries [powerKw] at [dT] K.
double flowForPowerM3h(double powerKw, double rho, double cp, double dT) {
  if (dT == 0) throw ArgumentError('ΔT must be non-zero');
  return powerKw * 3600 / (rho * cp * dT);
}

const double kcalPerKwh = 859.845;

// ---------------------------------------------------------------------------
// Valves
// ---------------------------------------------------------------------------

/// Pressure drop across a valve, bar. ΔP = (Q / Kvs)²
double valvePressureDropBar(double flowM3h, double kvs) {
  if (kvs <= 0) throw ArgumentError('Kvs must be positive');
  return math.pow(flowM3h / kvs, 2).toDouble();
}

/// Required Kvs for [flowM3h] at [dpBar] pressure drop. Kv = Q / √ΔP
double requiredKvs(double flowM3h, double dpBar) {
  if (dpBar <= 0) throw ArgumentError('ΔP must be positive');
  return flowM3h / math.sqrt(dpBar);
}

// ---------------------------------------------------------------------------
// Expansion tank
// ---------------------------------------------------------------------------

const List<int> standardTankSizes = [
  5,
  8,
  12,
  18,
  24,
  35,
  50,
  80,
  100,
  150,
  200,
  250,
  300,
  400,
  500,
  750,
  1000,
];

class ExpansionResult {
  const ExpansionResult({
    required this.expansionVolume,
    required this.tankVolume,
    required this.recommended,
    required this.efficiency,
  });

  /// ΔV, litres of fluid expansion.
  final double expansionVolume;

  /// Required tank volume, litres.
  final double tankVolume;

  /// Nearest standard size, litres (null if larger than the largest standard).
  final int? recommended;

  /// Tank efficiency factor (Pmax − P0)/(Pmax + 1).
  final double efficiency;
}

/// Volumetric expansion coefficient for the selected fluid, 1/K.
double expansionCoefficient(Fluid fluid, int concentration, double avgTemp) {
  if (fluid == Fluid.water) return interpolate(waterAlpha, avgTemp);
  // Glycol mixtures expand more than water; simple linear model by concentration.
  return 0.00045 + concentration * 0.000005;
}

/// Expansion tank sizing (membrane tank, closed system).
///
/// [systemVolume] litres, [tMin]/[tMax] °C, [p0]/[pMax] gauge bar.
ExpansionResult expansionTank({
  required double systemVolume,
  required double tMin,
  required double tMax,
  required double p0,
  required double pMax,
  required Fluid fluid,
  int concentration = 30,
}) {
  if (systemVolume <= 0) throw ArgumentError('system volume must be positive');
  if (tMax <= tMin) throw ArgumentError('tMax must be greater than tMin');
  if (pMax <= p0) throw ArgumentError('pMax must be greater than p0');
  if (p0 < 0) throw ArgumentError('p0 must be non-negative');

  final alpha = expansionCoefficient(fluid, concentration, (tMin + tMax) / 2);
  final dV = systemVolume * alpha * (tMax - tMin);
  final efficiency = (pMax - p0) / (pMax + 1);
  final vt = dV / efficiency;
  int? rec;
  for (final s in standardTankSizes) {
    if (s >= vt) {
      rec = s;
      break;
    }
  }
  return ExpansionResult(
    expansionVolume: dV,
    tankVolume: vt,
    recommended: rec,
    efficiency: efficiency,
  );
}

/// Rule of thumb: system water content, litres per kW of installed power.
const double litresPerKw = 12;

// ---------------------------------------------------------------------------
// Insulation
// ---------------------------------------------------------------------------

class InsulationResult {
  const InsulationResult({
    required this.outerDiameter,
    required this.insulatedDiameter,
    required this.area,
    required this.volume,
    required this.areaPerMeter,
  });

  final double outerDiameter; // mm
  final double insulatedDiameter; // mm
  final double area; // m²
  final double volume; // m³
  final double areaPerMeter; // m²/m
}

InsulationResult insulation({
  required double outerDiameterMm,
  required double thicknessMm,
  required double lengthM,
}) {
  if (outerDiameterMm <= 0) throw ArgumentError('diameter must be positive');
  if (thicknessMm <= 0) throw ArgumentError('thickness must be positive');
  if (lengthM < 0) throw ArgumentError('length must be non-negative');
  final dIns = outerDiameterMm + 2 * thicknessMm;
  final perMeter = math.pi * dIns / 1000;
  final area = perMeter * lengthM;
  final volume =
      math.pi *
      (math.pow(dIns / 2, 2) - math.pow(outerDiameterMm / 2, 2)) /
      1e6 *
      lengthM;
  return InsulationResult(
    outerDiameter: outerDiameterMm,
    insulatedDiameter: dIns,
    area: area,
    volume: volume,
    areaPerMeter: perMeter,
  );
}
