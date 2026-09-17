import 'package:flutter/material.dart';

import '../app_settings.dart';
import '../core/calc.dart';
import '../core/format.dart';
import 'widgets.dart';

double? _num(TextEditingController c) => parseNumber(c.text);

String _u(BuildContext context, String en, String ru) =>
    context.l.isRu ? ru : en;

String _matKey(PipeMaterial m) => switch (m) {
  PipeMaterial.steel => 'mat_steel',
  PipeMaterial.ppr => 'mat_ppr',
  PipeMaterial.pex => 'mat_pex',
  PipeMaterial.copper => 'mat_copper',
};

String _fluidKey(Fluid f) => switch (f) {
  Fluid.water => 'water',
  Fluid.ethyleneGlycol => 'ethylene_glycol',
  Fluid.propyleneGlycol => 'propylene_glycol',
};

String _sizeLabel(BuildContext context, PipeMaterial m, PipeSize s) {
  final mm = _u(context, 'mm', 'мм');
  final od = fmt(context, s.outer, significant: 4);
  final wall = fmt(context, s.wall, significant: 3);
  return m == PipeMaterial.steel
      ? 'DN ${s.nominal}   (Ø$od × $wall $mm)'
      : 'Ø$od × $wall $mm';
}

// ===========================================================================
// 1. Pipe velocity
// ===========================================================================

class VelocityPage extends StatefulWidget {
  const VelocityPage({super.key});

  @override
  State<VelocityPage> createState() => _VelocityPageState();
}

class _VelocityPageState extends State<VelocityPage> {
  final _flow = TextEditingController();
  PipeMaterial _material = PipeMaterial.steel;
  PipeSize _size = pipeDatabase[PipeMaterial.steel]![2];

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final scheme = Theme.of(context).colorScheme;
    final flow = _num(_flow);
    final sizes = pipeDatabase[_material]!;
    final valid = flow != null && flow > 0;
    final ms = _u(context, 'm/s', 'м/с');
    final mm = _u(context, 'mm', 'мм');

    double? v;
    VelocityRating? rating;
    if (valid) {
      v = pipeVelocity(flow, _size.inner);
      rating = rateVelocity(v);
    }

    Color ratingColor(VelocityRating r) => switch (r) {
      VelocityRating.low => scheme.tertiary,
      VelocityRating.ok => const Color(0xFF2E9E5B),
      VelocityRating.high => scheme.error,
    };
    String ratingText(VelocityRating r) => switch (r) {
      VelocityRating.low => l['velocity_low'],
      VelocityRating.ok => l['velocity_ok'],
      VelocityRating.high => l['velocity_high'],
    };

    return CalcScaffold(
      title: l['calc_velocity'],
      children: [
        NumField(
          controller: _flow,
          label: l['flow_rate'],
          autofocus: true,
          onChanged: (_) => setState(() {}),
        ),
        ChoiceField<PipeMaterial>(
          label: l['pipe_material'],
          value: _material,
          items: PipeMaterial.values,
          itemLabel: (m) => l[_matKey(m)],
          onChanged: (m) => setState(() {
            _material = m;
            _size = pipeDatabase[m]!.first;
          }),
        ),
        ChoiceField<PipeSize>(
          label: l['pipe_size'],
          value: _size,
          items: sizes,
          itemLabel: (s) => _sizeLabel(context, _material, s),
          onChanged: (s) => setState(() => _size = s),
        ),
        if (v != null && rating != null)
          ResultCard(
            rows: [
              ResultRow(
                l['velocity'],
                fmt(context, v, significant: 4),
                unit: ms,
                emphasis: true,
              ),
              ResultRow(
                l['inner_diameter'],
                fmt(context, _size.inner, significant: 4),
                unit: mm,
              ),
              ResultRow(
                l['flow_rate'].split(',').first,
                fmt(context, flow! / 3.6, significant: 4),
                unit: _u(context, 'L/s', 'л/с'),
              ),
            ],
            note: ratingText(rating),
            noteColor: ratingColor(rating),
          ),
        if (valid)
          Card(
            child: Column(
              children: [
                for (final s in sizes)
                  Builder(
                    builder: (context) {
                      final vs = pipeVelocity(flow, s.inner);
                      final r = rateVelocity(vs);
                      final selected = identical(s, _size);
                      return ListTile(
                        dense: true,
                        selected: selected,
                        selectedTileColor: scheme.primaryContainer.withValues(
                          alpha: 0.5,
                        ),
                        leading: Icon(
                          Icons.circle,
                          size: 12,
                          color: ratingColor(r),
                        ),
                        title: Text(_sizeLabel(context, _material, s)),
                        trailing: Text(
                          '${fmt(context, vs, significant: 3)} $ms',
                          style: TextStyle(
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        onTap: () => setState(() => _size = s),
                      );
                    },
                  ),
              ],
            ),
          ),
        InfoCard(l['velocity_info']),
      ],
    );
  }
}

// ===========================================================================
// 2. Thermal power
// ===========================================================================

enum _PowerMode { power, flow }

class PowerPage extends StatefulWidget {
  const PowerPage({super.key});

  @override
  State<PowerPage> createState() => _PowerPageState();
}

class _PowerPageState extends State<PowerPage> {
  _PowerMode _mode = _PowerMode.power;
  final _input = TextEditingController();
  final _dt = TextEditingController(text: '20');
  final _tavg = TextEditingController(text: '70');
  Fluid _fluid = Fluid.water;
  int _conc = 30;

  @override
  void dispose() {
    _input.dispose();
    _dt.dispose();
    _tavg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final input = _num(_input);
    final dt = _num(_dt);
    final tavg = _num(_tavg) ?? 70;
    final (rho, cp) = fluidProperties(_fluid, _conc, tavg);
    final kw = _u(context, 'kW', 'кВт');
    final m3h = _u(context, 'm³/h', 'м³/ч');

    final valid = input != null && input > 0 && dt != null && dt > 0;
    List<ResultRow> rows = const [];
    if (valid) {
      if (_mode == _PowerMode.power) {
        final p = thermalPowerKw(input, rho, cp, dt);
        rows = [
          ResultRow(
            l['power_kw'].split(',').first,
            fmt(context, p, significant: 5),
            unit: kw,
            emphasis: true,
          ),
          ResultRow(
            '',
            fmt(context, p * kcalPerKwh, significant: 5),
            unit: _u(context, 'kcal/h', 'ккал/ч'),
          ),
          ResultRow(
            '',
            fmt(context, p * kcalPerKwh / 1e6, significant: 4),
            unit: _u(context, 'Gcal/h', 'Гкал/ч'),
          ),
          ResultRow(
            _u(context, 'Mass flow', 'Массовый расход'),
            fmt(context, input * rho, significant: 5),
            unit: _u(context, 'kg/h', 'кг/ч'),
          ),
        ];
      } else {
        final g = flowForPowerM3h(input, rho, cp, dt);
        rows = [
          ResultRow(
            l['flow_rate'].split(',').first,
            fmt(context, g, significant: 5),
            unit: m3h,
            emphasis: true,
          ),
          ResultRow(
            '',
            fmt(context, g / 3.6, significant: 5),
            unit: _u(context, 'L/s', 'л/с'),
          ),
          ResultRow(
            _u(context, 'Mass flow', 'Массовый расход'),
            fmt(context, g * rho, significant: 5),
            unit: _u(context, 'kg/h', 'кг/ч'),
          ),
        ];
      }
    }

    return CalcScaffold(
      title: l['calc_power'],
      children: [
        SegmentedButton<_PowerMode>(
          showSelectedIcon: false,
          expandedInsets: EdgeInsets.zero,
          segments: [
            ButtonSegment(
              value: _PowerMode.power,
              label: Text(l['mode_power']),
            ),
            ButtonSegment(value: _PowerMode.flow, label: Text(l['mode_flow'])),
          ],
          selected: {_mode},
          onSelectionChanged: (s) => setState(() => _mode = s.first),
        ),
        NumField(
          controller: _input,
          label: _mode == _PowerMode.power ? l['flow_rate'] : l['power_kw'],
          autofocus: true,
          onChanged: (_) => setState(() {}),
        ),
        NumField(
          controller: _dt,
          label: l['temp_diff'],
          onChanged: (_) => setState(() {}),
        ),
        ChoiceField<Fluid>(
          label: l['fluid'],
          value: _fluid,
          items: Fluid.values,
          itemLabel: (f) => l[_fluidKey(f)],
          onChanged: (f) => setState(() => _fluid = f),
        ),
        if (_fluid != Fluid.water)
          ChoiceField<int>(
            label: l['concentration'],
            value: _conc,
            items: glycolConcentrations,
            itemLabel: (c) => '$c %',
            onChanged: (c) => setState(() => _conc = c),
          ),
        NumField(
          controller: _tavg,
          label: l['avg_temp'],
          onChanged: (_) => setState(() {}),
        ),
        Text(
          '${l['density']}: ${fmt(context, rho, significant: 5)} ${_u(context, 'kg/m³', 'кг/м³')}     '
          '${l['specific_heat']}: ${fmt(context, cp, significant: 4)} ${_u(context, 'kJ/(kg·K)', 'кДж/(кг·К)')}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (dt != null && dt <= 0) ErrorNote(l['enter_valid_values']),
        if (rows.isNotEmpty) ResultCard(rows: rows),
      ],
    );
  }
}

// ===========================================================================
// 3. Valve pressure drop / Kvs selection
// ===========================================================================

enum _ValveMode { dp, kvs }

class ValvePage extends StatefulWidget {
  const ValvePage({super.key});

  @override
  State<ValvePage> createState() => _ValvePageState();
}

class _ValvePageState extends State<ValvePage> {
  _ValveMode _mode = _ValveMode.dp;
  final _flow = TextEditingController();
  final _second = TextEditingController();

  @override
  void dispose() {
    _flow.dispose();
    _second.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final flow = _num(_flow);
    final second = _num(_second);
    final valid = flow != null && flow >= 0 && second != null && second > 0;

    List<ResultRow> rows = const [];
    if (valid) {
      if (_mode == _ValveMode.dp) {
        final dp = valvePressureDropBar(flow, second);
        rows = [
          ResultRow(
            l['pressure_drop'],
            fmt(context, dp, significant: 4),
            unit: _u(context, 'bar', 'бар'),
            emphasis: true,
          ),
          ResultRow(
            '',
            fmt(context, dp * 100, significant: 4),
            unit: _u(context, 'kPa', 'кПа'),
          ),
          ResultRow(
            '',
            fmt(context, dp * 10.1972, significant: 4),
            unit: _u(context, 'mH₂O', 'м вод.ст.'),
          ),
        ];
      } else {
        final kvs = requiredKvs(flow, second);
        rows = [
          ResultRow(
            l['required_kvs'],
            fmt(context, kvs, significant: 4),
            unit: _u(context, 'm³/h', 'м³/ч'),
            emphasis: true,
          ),
        ];
      }
    }

    return CalcScaffold(
      title: l['calc_valve'],
      children: [
        SegmentedButton<_ValveMode>(
          showSelectedIcon: false,
          expandedInsets: EdgeInsets.zero,
          segments: [
            ButtonSegment(value: _ValveMode.dp, label: Text(l['mode_dp'])),
            ButtonSegment(value: _ValveMode.kvs, label: Text(l['mode_kvs'])),
          ],
          selected: {_mode},
          onSelectionChanged: (s) => setState(() => _mode = s.first),
        ),
        NumField(
          controller: _flow,
          label: l['flow_rate'],
          autofocus: true,
          onChanged: (_) => setState(() {}),
        ),
        NumField(
          controller: _second,
          label: _mode == _ValveMode.dp ? l['kvs'] : l['dp_bar'],
          onChanged: (_) => setState(() {}),
        ),
        if (rows.isNotEmpty) ResultCard(rows: rows),
        InfoCard(l['kvs_info']),
      ],
    );
  }
}

// ===========================================================================
// 4. Expansion tank
// ===========================================================================

class TankPage extends StatefulWidget {
  const TankPage({super.key});

  @override
  State<TankPage> createState() => _TankPageState();
}

class _TankPageState extends State<TankPage> {
  Fluid _fluid = Fluid.water;
  int _conc = 30;
  final _power = TextEditingController();
  final _volume = TextEditingController();
  final _tmin = TextEditingController(text: '10');
  final _tmax = TextEditingController(text: '90');
  final _p0 = TextEditingController(text: '1.5');
  final _pmax = TextEditingController(text: '3');

  @override
  void dispose() {
    for (final c in [_power, _volume, _tmin, _tmax, _p0, _pmax]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final litre = _u(context, 'L', 'л');
    final volume = _num(_volume);
    final tmin = _num(_tmin);
    final tmax = _num(_tmax);
    final p0 = _num(_p0);
    final pmax = _num(_pmax);

    String? error;
    ExpansionResult? res;
    if (volume != null &&
        tmin != null &&
        tmax != null &&
        p0 != null &&
        pmax != null) {
      if (tmax <= tmin) {
        error = l['err_tmax'];
      } else if (pmax <= p0) {
        error = l['err_pmax'];
      } else if (volume > 0 && p0 >= 0) {
        res = expansionTank(
          systemVolume: volume,
          tMin: tmin,
          tMax: tmax,
          p0: p0,
          pMax: pmax,
          fluid: _fluid,
          concentration: _conc,
        );
      }
    }

    return CalcScaffold(
      title: l['calc_tank'],
      children: [
        ChoiceField<Fluid>(
          label: l['fluid'],
          value: _fluid,
          items: Fluid.values,
          itemLabel: (f) => l[_fluidKey(f)],
          onChanged: (f) => setState(() => _fluid = f),
        ),
        if (_fluid != Fluid.water)
          ChoiceField<int>(
            label: l['concentration'],
            value: _conc,
            items: glycolConcentrations,
            itemLabel: (c) => '$c %',
            onChanged: (c) => setState(() => _conc = c),
          ),
        NumField(
          controller: _power,
          label: l['system_power'],
          helper: l['volume_hint'],
          onChanged: (t) {
            final p = parseNumber(t);
            if (p != null && p > 0) {
              _volume.text = formatForInput(p * litresPerKw);
            }
            setState(() {});
          },
        ),
        NumField(
          controller: _volume,
          label: l['system_volume'],
          onChanged: (_) => setState(() {}),
        ),
        Row(
          children: [
            Expanded(
              child: NumField(
                controller: _tmin,
                label: l['min_temp'],
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NumField(
                controller: _tmax,
                label: l['max_temp'],
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: NumField(
                controller: _p0,
                label: l['precharge'],
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NumField(
                controller: _pmax,
                label: l['max_pressure'],
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        if (error != null) ErrorNote(error),
        if (res != null)
          ResultCard(
            rows: [
              ResultRow(
                l['tank_volume'],
                fmt(context, res.tankVolume, significant: 4),
                unit: litre,
                emphasis: true,
              ),
              ResultRow(
                l['recommended'],
                res.recommended?.toString() ?? '> ${standardTankSizes.last}',
                unit: litre,
                emphasis: true,
              ),
              ResultRow(
                l['expansion_volume'],
                fmt(context, res.expansionVolume, significant: 4),
                unit: litre,
              ),
              ResultRow(
                _u(context, 'Tank efficiency', 'Коэффициент использования'),
                fmt(context, res.efficiency * 100, significant: 3),
                unit: '%',
              ),
            ],
            note: res.recommended == null ? l['tank_too_big'] : null,
            noteColor: Theme.of(context).colorScheme.error,
          ),
        InfoCard(l['tank_info']),
      ],
    );
  }
}

// ===========================================================================
// 5. Pipe insulation
// ===========================================================================

class InsulationPage extends StatefulWidget {
  const InsulationPage({super.key});

  @override
  State<InsulationPage> createState() => _InsulationPageState();
}

class _InsulationPageState extends State<InsulationPage> {
  final _od = TextEditingController();
  final _thk = TextEditingController(text: '50');
  final _len = TextEditingController();

  @override
  void dispose() {
    _od.dispose();
    _thk.dispose();
    _len.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final od = _num(_od);
    final thk = _num(_thk);
    final len = _num(_len);
    final mm = _u(context, 'mm', 'мм');

    InsulationResult? res;
    if (od != null &&
        od > 0 &&
        thk != null &&
        thk > 0 &&
        len != null &&
        len >= 0) {
      res = insulation(outerDiameterMm: od, thicknessMm: thk, lengthM: len);
    }

    return CalcScaffold(
      title: l['calc_insulation'],
      children: [
        NumField(
          controller: _od,
          label: l['outer_diameter'],
          autofocus: true,
          onChanged: (_) => setState(() {}),
        ),
        Wrap(
          spacing: 6,
          runSpacing: -6,
          children: [
            for (final s in pipeDatabase[PipeMaterial.steel]!)
              ActionChip(
                label: Text('${s.nominal}'),
                visualDensity: VisualDensity.compact,
                onPressed: () =>
                    setState(() => _od.text = formatForInput(s.outer)),
              ),
          ],
        ),
        NumField(
          controller: _thk,
          label: l['ins_thickness'],
          onChanged: (_) => setState(() {}),
        ),
        NumField(
          controller: _len,
          label: l['pipe_length'],
          onChanged: (_) => setState(() {}),
        ),
        if (res != null)
          ResultCard(
            rows: [
              ResultRow(
                l['ins_area'],
                fmt(context, res.area, significant: 5),
                unit: 'м²'.replaceAll('м', _u(context, 'm', 'м')),
                emphasis: true,
              ),
              ResultRow(
                '${l['ins_area']} (${l['ins_area_per_m']})',
                fmt(context, res.areaPerMeter, significant: 4),
                unit: _u(context, 'm²/m', 'м²/м'),
              ),
              ResultRow(
                l['ins_volume'],
                fmt(context, res.volume, significant: 4),
                unit: _u(context, 'm³', 'м³'),
              ),
              ResultRow(
                l['insulated_diameter'],
                fmt(context, res.insulatedDiameter, significant: 4),
                unit: mm,
              ),
            ],
          ),
        InfoCard(l['ins_info']),
      ],
    );
  }
}
