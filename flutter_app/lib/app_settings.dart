import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/l10n.dart';

/// User preferences persisted between launches.
class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs)
    : lang = _prefs.getString('lang') ?? _systemLang(),
      themeMode = ThemeMode.values[_prefs.getInt('theme') ?? 0],
      lastCategory = _prefs.getString('cat') ?? 'pressure',
      lastFrom = _prefs.getString('from'),
      lastTo = _prefs.getString('to');

  static Future<AppSettings> load() async =>
      AppSettings._(await SharedPreferences.getInstance());

  static String _systemLang() {
    final code = PlatformDispatcher.instance.locale.languageCode;
    return supportedLangs.contains(code) ? code : 'en';
  }

  final SharedPreferences _prefs;

  String lang;
  ThemeMode themeMode;
  String lastCategory;
  String? lastFrom;
  String? lastTo;

  L10n get l => L10n(lang);

  Future<void> setLang(String value) async {
    if (value == lang) return;
    lang = value;
    notifyListeners();
    await _prefs.setString('lang', value);
  }

  Future<void> setThemeMode(ThemeMode value) async {
    if (value == themeMode) return;
    themeMode = value;
    notifyListeners();
    await _prefs.setInt('theme', value.index);
  }

  Future<void> rememberConversion(
    String category,
    String from,
    String to,
  ) async {
    lastCategory = category;
    lastFrom = from;
    lastTo = to;
    await _prefs.setString('cat', category);
    await _prefs.setString('from', from);
    await _prefs.setString('to', to);
  }
}

class SettingsScope extends InheritedNotifier<AppSettings> {
  const SettingsScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static AppSettings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsScope>()!.notifier!;

  /// Reads the settings without subscribing to changes.
  /// Safe to call from initState() and event handlers.
  static AppSettings read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<SettingsScope>()!.notifier!;
}

extension L10nContext on BuildContext {
  L10n get l => SettingsScope.of(this).l;
  AppSettings get settings => SettingsScope.of(this);
}
