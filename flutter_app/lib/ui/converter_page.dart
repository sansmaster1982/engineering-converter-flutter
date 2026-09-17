import 'package:flutter/material.dart';

import '../app_settings.dart';
import '../core/format.dart';
import '../core/units.dart';
import 'widgets.dart';

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> {
  final _ctrl = TextEditingController();
  late UnitCategory _cat;
  late Unit _from;
  late Unit _to;

  /// Remembers the unit pair chosen in each category during the session.
  final Map<String, (String, String)> _pairs = {};

  @override
  void initState() {
    super.initState();
    final s = SettingsScope.read(context);
    _cat = categoryById(s.lastCategory);
    _from = _cat.units.firstWhere(
      (u) => u.id == s.lastFrom,
      orElse: () => _cat.units.first,
    );
    _to = _cat.units.firstWhere(
      (u) => u.id == s.lastTo,
      orElse: () => _cat.units[1],
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double? get _value => parseNumber(_ctrl.text);

  double? get _result {
    final v = _value;
    return v == null ? null : _cat.convert(v, _from, _to);
  }

  void _remember() =>
      SettingsScope.read(context).rememberConversion(_cat.id, _from.id, _to.id);

  void _selectCategory(UnitCategory cat) {
    if (cat.id == _cat.id) return;
    _pairs[_cat.id] = (_from.id, _to.id);
    setState(() {
      _cat = cat;
      final saved = _pairs[cat.id];
      _from = saved == null ? cat.units[0] : cat.unitById(saved.$1);
      _to = saved == null ? cat.units[1] : cat.unitById(saved.$2);
    });
    _remember();
  }

  void _swap() {
    final r = _result;
    setState(() {
      final t = _from;
      _from = _to;
      _to = t;
      if (r != null) {
        _ctrl.text = formatForInput(r)
            .replaceAll('.', context.l.isRu ? ',' : '.');
      }
    });
    _remember();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final lang = l.lang;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final value = _value;
    final result = _result;

    return Scaffold(
      appBar: AppBar(
        title: Text(l['tab_converter']),
        actions: [
          IconButton(
            tooltip: l['clear'],
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () => setState(_ctrl.clear),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            // ---- category chips ----
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final c = categories[i];
                  return ChoiceChip(
                    label: Text(l['cat_${c.id}']),
                    selected: c.id == _cat.id,
                    onSelected: (_) => _selectCategory(c),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // ---- value ----
            NumField(
              controller: _ctrl,
              label: l['value'],
              suffix: _from.label(lang),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            // ---- units ----
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: ChoiceField<Unit>(
                    label: l['from'],
                    value: _from,
                    items: _cat.units,
                    itemLabel: (u) => u.label(lang),
                    onChanged: (u) {
                      setState(() => _from = u);
                      _remember();
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: IconButton.filledTonal(
                    tooltip: l['swap'],
                    icon: const Icon(Icons.swap_horiz),
                    onPressed: _swap,
                  ),
                ),
                Expanded(
                  child: ChoiceField<Unit>(
                    label: l['to'],
                    value: _to,
                    items: _cat.units,
                    itemLabel: (u) => u.label(lang),
                    onChanged: (u) {
                      setState(() => _to = u);
                      _remember();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ---- result ----
            Card(
              color: scheme.primary,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: result == null
                    ? null
                    : () => copyToClipboard(context, fmt(context, result)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value == null
                            ? l['result']
                            : '${fmt(context, value)} ${_from.label(lang)} =',
                        style: text.bodyMedium?.copyWith(
                          color: scheme.onPrimary.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text.rich(
                          TextSpan(
                            text: result == null ? '—' : fmt(context, result),
                            style: text.displaySmall?.copyWith(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                            children: [
                              TextSpan(
                                text: '  ${_to.label(lang)}',
                                style: text.titleLarge?.copyWith(
                                  color: scheme.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ---- all units ----
            if (value != null) ...[
              Text(l['all_conversions'], style: text.titleMedium),
              const SizedBox(height: 8),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < _cat.units.length; i++)
                      _UnitRow(
                        unit: _cat.units[i],
                        value: _cat.convert(value, _from, _cat.units[i]),
                        highlighted: _cat.units[i].id == _to.id,
                        striped: i.isOdd,
                        onTap: () {
                          setState(() => _to = _cat.units[i]);
                          _remember();
                        },
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UnitRow extends StatelessWidget {
  const _UnitRow({
    required this.unit,
    required this.value,
    required this.highlighted,
    required this.striped,
    required this.onTap,
  });

  final Unit unit;
  final double value;
  final bool highlighted;
  final bool striped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final formatted = fmt(context, value);
    return Material(
      color: highlighted
          ? scheme.primaryContainer.withValues(alpha: 0.6)
          : striped
          ? scheme.surfaceContainerLow
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: () => copyToClipboard(context, formatted),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(unit.label(context.l.lang), style: text.bodyLarge),
              ),
              Text(
                formatted,
                style: text.bodyLarge?.copyWith(
                  fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.copy_outlined, size: 18),
                tooltip: context.l['copied'],
                onPressed: () => copyToClipboard(context, formatted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
