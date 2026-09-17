import 'package:engconverter/core/calc.dart';
import 'package:engconverter/core/format.dart';
import 'package:engconverter/core/units.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('units', () {
    final pressure = categoryById('pressure');
    test('1 bar = 100000 Pa', () {
      expect(
        pressure.convert(1, pressure.unitById('bar'), pressure.unitById('Pa')),
        100000,
      );
    });
    test('1 kgf/cm2 = 0.980665 bar', () {
      expect(
        pressure.convert(
          1,
          pressure.unitById('kgf_cm2'),
          pressure.unitById('bar'),
        ),
        closeTo(0.980665, 1e-9),
      );
    });
    test('1 MPa = 101.972 mH2O', () {
      expect(
        pressure.convert(
          1,
          pressure.unitById('MPa'),
          pressure.unitById('mH2O'),
        ),
        closeTo(101.972, 0.01),
      );
    });
    test('round trip keeps value', () {
      for (final cat in categories) {
        for (final a in cat.units) {
          for (final b in cat.units) {
            final back = cat.convert(cat.convert(123.456, a, b), b, a);
            expect(
              back,
              closeTo(123.456, 1e-6),
              reason: '${cat.id}: ${a.id} -> ${b.id}',
            );
          }
        }
      }
    });
    test('temperature', () {
      expect(convertTemperature(100, 'C', 'F'), closeTo(212, 1e-9));
      expect(convertTemperature(-40, 'C', 'F'), closeTo(-40, 1e-9));
      expect(convertTemperature(0, 'C', 'K'), closeTo(273.15, 1e-9));
      expect(convertTemperature(32, 'F', 'C'), closeTo(0, 1e-9));
    });
    test('flow: 1 m3/h = 0.27778 L/s', () {
      final flow = categoryById('flow');
      expect(
        flow.convert(1, flow.unitById('m3_h'), flow.unitById('L_s')),
        closeTo(0.277778, 1e-6),
      );
    });
    test('power: 1 kW = 859.85 kcal/h', () {
      final power = categoryById('power');
      expect(
        power.convert(1, power.unitById('kW'), power.unitById('kcal_h')),
        closeTo(859.85, 0.01),
      );
    });
    test('every unit has a unique id inside its category', () {
      for (final cat in categories) {
        final ids = cat.units.map((u) => u.id).toSet();
        expect(ids.length, cat.units.length, reason: cat.id);
      }
    });
  });

  group('parseNumber', () {
    test('accepts comma and dot', () {
      expect(parseNumber('1,5'), 1.5);
      expect(parseNumber('1.5'), 1.5);
      expect(parseNumber(' 1 500 '), 1500);
      expect(parseNumber('-40'), -40);
      expect(parseNumber('1e-3'), 0.001);
    });
    test('rejects garbage', () {
      expect(parseNumber(''), isNull);
      expect(parseNumber('-'), isNull);
      expect(parseNumber('.'), isNull);
      expect(parseNumber('abc'), isNull);
      expect(parseNumber('1..2'), isNull);
    });
  });

  group('formatNumber', () {
    const thin = ' ';
    test('zero and integers', () {
      expect(formatNumber(0), '0');
      expect(formatNumber(-0.0), '0');
      expect(formatNumber(100000), '100${thin}000');
      expect(formatNumber(2000000), '2${thin}000${thin}000');
      expect(formatNumber(1234), '1234');
      expect(formatNumber(-40), '-40');
    });
    test('fractions keep 6 significant digits', () {
      expect(formatNumber(273.15), '273.15');
      expect(formatNumber(1234.5678), '1234.57');
      expect(formatNumber(12345.678), '12${thin}345.7');
      expect(formatNumber(0.001), '0.001');
      expect(formatNumber(0.0001), '0.0001');
      expect(formatNumber(1 / 3), '0.333333');
      expect(formatNumber(0.980665), '0.980665');
    });
    test('scientific only for extreme values', () {
      expect(formatNumber(0.00001), '1e-5');
      expect(formatNumber(0.0000101972), '1.01972e-5');
      expect(formatNumber(1e-7), '1e-7');
      expect(formatNumber(2e15), '2e+15');
    });
    test('locale decimal separator', () {
      expect(formatNumber(1.5, decimal: ','), '1,5');
      expect(formatNumber(1234.5, decimal: ',', group: false), '1234,5');
    });
    test('formatForInput has no grouping', () {
      expect(formatForInput(100000), '100000');
      expect(formatForInput(0.000001), '0.000001');
    });
  });

  group('calc', () {
    test('pipe velocity 10 m3/h in DN50 steel', () {
      final dn50 = pipeDatabase[PipeMaterial.steel]!.firstWhere(
        (s) => s.nominal == 50,
      );
      expect(dn50.inner, closeTo(53, 1e-9));
      expect(pipeVelocity(10, dn50.inner), closeTo(1.2591, 1e-3));
      expect(pipeFlowForVelocity(1.2591, dn50.inner), closeTo(10, 1e-2));
    });
    test('velocity rating', () {
      expect(rateVelocity(0.1), VelocityRating.low);
      expect(rateVelocity(1.0), VelocityRating.ok);
      expect(rateVelocity(3.0), VelocityRating.high);
    });
    test('thermal power water', () {
      final (rho, cp) = fluidProperties(Fluid.water, 0, 70);
      expect(cp, closeTo(4.189, 1e-9));
      expect(rho, closeTo(977.8, 1e-9));
      expect(thermalPowerKw(10, 1000, 4.189, 20), closeTo(232.72, 0.01));
      expect(flowForPowerM3h(232.72, 1000, 4.189, 20), closeTo(10, 0.001));
    });
    test('thermal power glycol 40 %', () {
      final (rho, cp) = fluidProperties(Fluid.ethyleneGlycol, 40, 70);
      expect(thermalPowerKw(10, rho, cp, 20), closeTo(194.33, 0.01));
    });
    test('interpolation clamps and interpolates', () {
      expect(interpolate(waterSpecificHeat, -20), 4.218);
      expect(interpolate(waterSpecificHeat, 200), 4.216);
      expect(
        interpolate(waterSpecificHeat, 75),
        closeTo((4.189 + 4.196) / 2, 1e-9),
      );
    });
    test('valve', () {
      expect(valvePressureDropBar(5, 10), closeTo(0.25, 1e-12));
      expect(requiredKvs(5, 0.25), closeTo(10, 1e-12));
      expect(() => valvePressureDropBar(5, 0), throwsArgumentError);
    });
    test('expansion tank water 1200 L, 10-90 C, 1.5/3 bar', () {
      final r = expansionTank(
        systemVolume: 1200,
        tMin: 10,
        tMax: 90,
        p0: 1.5,
        pMax: 3,
        fluid: Fluid.water,
      );
      expect(r.expansionVolume, closeTo(43.87, 0.01));
      expect(r.tankVolume, closeTo(116.99, 0.01));
      expect(r.recommended, 150);
    });
    test('expansion tank rejects inverted inputs', () {
      expect(
        () => expansionTank(
          systemVolume: 100,
          tMin: 90,
          tMax: 10,
          p0: 1.5,
          pMax: 3,
          fluid: Fluid.water,
        ),
        throwsArgumentError,
      );
      expect(
        () => expansionTank(
          systemVolume: 100,
          tMin: 10,
          tMax: 90,
          p0: 3,
          pMax: 3,
          fluid: Fluid.water,
        ),
        throwsArgumentError,
      );
    });
    test('very large system has no standard tank', () {
      final r = expansionTank(
        systemVolume: 100000,
        tMin: 10,
        tMax: 90,
        p0: 1.5,
        pMax: 3,
        fluid: Fluid.water,
      );
      expect(r.recommended, isNull);
    });
    test('insulation OD 60, 50 mm, 10 m', () {
      final r = insulation(outerDiameterMm: 60, thicknessMm: 50, lengthM: 10);
      expect(r.insulatedDiameter, 160);
      expect(r.area, closeTo(5.0265, 1e-3));
      expect(r.volume, closeTo(0.1728, 1e-3));
    });
  });
}
