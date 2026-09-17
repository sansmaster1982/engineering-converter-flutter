import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_settings.dart';
import '../core/format.dart';

/// Numeric text field: numeric keyboard with decimal point and sign,
/// accepts both "." and "," as the decimal separator.
class NumField extends StatelessWidget {
  const NumField({
    super.key,
    required this.controller,
    required this.label,
    this.suffix,
    this.onChanged,
    this.helper,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final String? suffix;
  final String? helper;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  static final _allowed = FilteringTextInputFormatter.allow(
    RegExp(r'[0-9.,\-]'),
  );

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      inputFormatters: [_allowed],
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        helperText: helper,
        suffixIcon: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => controller.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  tooltip: context.l['clear'],
                  onPressed: () {
                    controller.clear();
                    onChanged?.call('');
                  },
                ),
        ),
      ),
      onChanged: onChanged,
    );
  }
}

/// Drop-down inside an outlined input decoration.
class ChoiceField<T> extends StatelessWidget {
  const ChoiceField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          borderRadius: BorderRadius.circular(12),
          items: [
            for (final item in items)
              DropdownMenuItem(
                value: item,
                child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class ResultRow {
  const ResultRow(this.label, this.value, {this.unit, this.emphasis = false});
  final String label;
  final String value;
  final String? unit;
  final bool emphasis;
}

/// Highlighted card with calculation results. Tapping a row copies the value.
class ResultCard extends StatelessWidget {
  const ResultCard({super.key, required this.rows, this.note, this.noteColor});

  final List<ResultRow> rows;
  final String? note;
  final Color? noteColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final r in rows)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => copyToClipboard(context, r.value),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          r.label,
                          style: text.bodyMedium?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        r.value,
                        style:
                            (r.emphasis ? text.headlineSmall : text.titleMedium)
                                ?.copyWith(
                                  color: scheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                      ),
                      if (r.unit != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          r.unit!,
                          style: text.bodyMedium?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            if (note != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: noteColor ?? scheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note!,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Muted card with reference information.
class InfoCard extends StatelessWidget {
  const InfoCard(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              size: 20,
              color: scheme.onSecondaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onSecondaryContainer, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small red hint under a form when inputs are inconsistent.
class ErrorNote extends StatelessWidget {
  const ErrorNote(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.error_outline, size: 18, color: scheme.error),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(color: scheme.error)),
        ),
      ],
    );
  }
}

/// Page scaffold used by every calculator: title, scrollable body, keyboard-safe padding.
class CalcScaffold extends StatelessWidget {
  const CalcScaffold({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            32 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> copyToClipboard(BuildContext context, String value) async {
  await Clipboard.setData(ClipboardData(text: value));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('${context.l['copied']}: $value'),
        duration: const Duration(seconds: 1),
      ),
    );
}

/// Locale-aware number formatting helper for widgets.
String fmt(BuildContext context, double v, {int significant = 6}) =>
    formatNumber(
      v,
      significant: significant,
      decimal: context.l.isRu ? ',' : '.',
    );
