import 'package:engconverter/app_settings.dart';
import 'package:engconverter/main.dart';
import 'package:engconverter/ui/about_page.dart';
import 'package:engconverter/ui/calc_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppSettings> settings({String lang = 'en'}) async {
  SharedPreferences.setMockInitialValues({'lang': lang});
  return AppSettings.load();
}

Widget wrap(Widget child, AppSettings s) => SettingsScope(
  settings: s,
  child: ListenableBuilder(
    listenable: s,
    builder: (_, _) => MaterialApp(home: child),
  ),
);

Finder field(String label) => find.widgetWithText(TextField, label);

void main() {
  testWidgets('converter: swap inverts the conversion', (tester) async {
    final s = await settings();
    await tester.pumpWidget(EngConverterApp(settings: s));
    await tester.pumpAndSettle();

    await tester.enterText(field('Value'), '1');
    await tester.pumpAndSettle();
    expect(find.text('0.001'), findsWidgets); // 1 Pa = 0.001 kPa in the list

    await tester.tap(find.byTooltip('Swap units'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '0.001'), findsOneWidget);
    expect(find.text('1'), findsWidgets); // 0.001 kPa = 1 Pa
  });

  testWidgets('converter: comma is accepted as decimal separator', (
    tester,
  ) async {
    final s = await settings();
    await tester.pumpWidget(EngConverterApp(settings: s));
    await tester.pumpAndSettle();

    await tester.enterText(field('Value'), '1,5');
    await tester.pumpAndSettle();
    expect(find.text('0.0015'), findsWidgets); // 1.5 Pa -> kPa
  });

  testWidgets('converter: zero and large values are formatted plainly', (
    tester,
  ) async {
    final s = await settings();
    await tester.pumpWidget(EngConverterApp(settings: s));
    await tester.pumpAndSettle();

    await tester.enterText(field('Value'), '0');
    await tester.pumpAndSettle();
    expect(find.text('0'), findsWidgets);
    expect(find.textContaining('e+'), findsNothing);

    await tester.enterText(field('Value'), '2000000');
    await tester.pumpAndSettle();
    expect(find.text('2 000 000'), findsWidgets);
  });

  testWidgets('tank page validates temperatures and sizes a tank', (
    tester,
  ) async {
    final s = await settings();
    await tester.pumpWidget(wrap(const TankPage(), s));
    await tester.pumpAndSettle();

    await tester.enterText(field('System volume, L'), '1200');
    await tester.pumpAndSettle();
    expect(find.text('117'), findsOneWidget);
    expect(find.text('150'), findsOneWidget);

    await tester.enterText(field('t₂ max, °C'), '5');
    await tester.pumpAndSettle();
    expect(find.text('t₂ must be greater than t₁'), findsOneWidget);
    expect(find.text('117'), findsNothing);
  });

  testWidgets('tank page: power estimates the system volume', (tester) async {
    final s = await settings();
    await tester.pumpWidget(wrap(const TankPage(), s));
    await tester.pumpAndSettle();
    await tester.enterText(field('System power, kW'), '100');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '1200'), findsOneWidget);
  });

  testWidgets('power page shows concentration only for glycol', (tester) async {
    final s = await settings();
    await tester.pumpWidget(wrap(const PowerPage(), s));
    await tester.pumpAndSettle();
    expect(find.text('Concentration, %'), findsNothing);

    await tester.tap(find.text('Water'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ethylene glycol').last);
    await tester.pumpAndSettle();
    expect(find.text('Concentration, %'), findsOneWidget);

    await tester.enterText(field('Flow rate, m³/h'), '10');
    await tester.pumpAndSettle();
    expect(find.text('203.19'), findsOneWidget); // 10·1045·3.5·20/3600
  });

  testWidgets('insulation page computes area for Ø60, 50 mm, 10 m', (
    tester,
  ) async {
    final s = await settings();
    await tester.pumpWidget(wrap(const InsulationPage(), s));
    await tester.pumpAndSettle();
    await tester.enterText(field('Pipe outer diameter, mm'), '60');
    await tester.enterText(field('Pipe length, m'), '10');
    await tester.pumpAndSettle();
    expect(find.text('5.0265'), findsOneWidget);
    expect(find.text('0.1728'), findsOneWidget);
  });

  testWidgets('about page switches language and persists it', (tester) async {
    final s = await settings();
    await tester.pumpWidget(wrap(const AboutPage(), s));
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);

    await tester.tap(find.text('Русский'));
    await tester.pumpAndSettle();
    expect(find.text('Язык'), findsOneWidget);
    expect(s.lang, 'ru');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('lang'), 'ru');
  });
}
