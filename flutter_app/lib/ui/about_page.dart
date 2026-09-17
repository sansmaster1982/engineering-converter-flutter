import 'package:flutter/material.dart';

import '../app_settings.dart';
import '../main.dart' show appVersion;

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final s = context.settings;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l['tab_about'])),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l['language'], style: text.titleSmall),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 'ru', label: Text('Русский')),
                      ButtonSegment(value: 'en', label: Text('English')),
                    ],
                    selected: {s.lang},
                    onSelectionChanged: (v) => s.setLang(v.first),
                  ),
                  const SizedBox(height: 16),
                  Text(l['theme'], style: text.titleSmall),
                  const SizedBox(height: 8),
                  SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text(l['theme_system']),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text(l['theme_light']),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text(l['theme_dark']),
                      ),
                    ],
                    selected: {s.themeMode},
                    onSelectionChanged: (v) => s.setThemeMode(v.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: scheme.primary,
                        child: Icon(
                          Icons.settings_suggest,
                          color: scheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l['app_title'], style: text.titleLarge),
                            Text(
                              '${l['version']} $appVersion',
                              style: text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l['about_text'],
                    style: text.bodyMedium?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  for (final key in const [
                    'calc_velocity',
                    'calc_power',
                    'calc_valve',
                    'calc_tank',
                    'calc_insulation',
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(Icons.check, size: 18, color: scheme.primary),
                          const SizedBox(width: 8),
                          Text(l[key]),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text('© 2024–2026', style: text.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
