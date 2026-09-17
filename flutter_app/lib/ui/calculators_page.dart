import 'package:flutter/material.dart';

import '../app_settings.dart';
import 'calc_pages.dart';

class CalculatorsPage extends StatelessWidget {
  const CalculatorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final items = <(IconData, String, String, Widget Function())>[
      (
        Icons.speed,
        'calc_velocity',
        'calc_velocity_sub',
        () => const VelocityPage(),
      ),
      (
        Icons.local_fire_department_outlined,
        'calc_power',
        'calc_power_sub',
        () => const PowerPage(),
      ),
      (Icons.compress, 'calc_valve', 'calc_valve_sub', () => const ValvePage()),
      (
        Icons.propane_tank_outlined,
        'calc_tank',
        'calc_tank_sub',
        () => const TankPage(),
      ),
      (
        Icons.layers_outlined,
        'calc_insulation',
        'calc_insulation_sub',
        () => const InsulationPage(),
      ),
    ];
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l['tab_calcs'])),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final (icon, title, sub, builder) = items[i];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: Icon(icon),
              ),
              title: Text(
                l[title],
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(l[sub]),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => builder())),
            ),
          );
        },
      ),
    );
  }
}
