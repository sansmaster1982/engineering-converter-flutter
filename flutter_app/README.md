# Eng Converter — Flutter version (v6)

Единая кодовая база для Android и iOS. Заменяет две расходящиеся Kivy-копии (`main.py`, `IOS/main.py`).

## Структура

```
lib/
  main.dart            — тема, навигация (3 вкладки), запуск
  app_settings.dart    — язык, тема, последние единицы (shared_preferences)
  core/
    units.dart         — категории и единицы с коэффициентами, RU/EN подписи
    calc.dart          — инженерные расчёты (чистые функции, без Flutter)
    format.dart        — разбор ввода (принимает «,» и «.») и форматирование чисел
    l10n.dart          — строки интерфейса RU/EN
  ui/
    converter_page.dart    — конвертер
    calculators_page.dart  — список расчётов
    calc_pages.dart        — 5 экранов расчётов
    about_page.dart        — настройки и «О программе»
    widgets.dart           — общие виджеты (поля, карточки результата)
test/core_test.dart    — тесты расчётов и форматирования
```

## Сборка

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release        # android/key.properties + release-key.jks для подписи
flutter build appbundle --release  # для Google Play
flutter build ios --release        # только на macOS; см. .github/workflows/build-flutter.yml
```

Идентификаторы сохранены от прежних версий, чтобы обновления в магазинах встали поверх старых:

| Платформа | ID | Версия |
|-----------|----|--------|
| Android   | `org.engineering.engconverter`, versionCode 202160000 (> 202150700) | 6.0.0 |
| iOS       | `com.engtools.engconverter`, build 202160000 (> 4) | 6.0.0 |

Минимальный Android — 7.0 (API 24, значение по умолчанию у Flutter), iOS — 13.

Подпись Android: файл `android/key.properties` (в `.gitignore`) с полями
`storeFile`, `storePassword`, `keyAlias`, `keyPassword`; keystore кладётся в `android/app/release-key.jks`.
