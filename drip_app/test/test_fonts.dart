import 'package:flutter/services.dart';

/// `flutter_test` doesn't load the fonts declared in pubspec.yaml, so text
/// falls back to a wide placeholder face and layouts overflow. Loading the real
/// bundled fonts makes widget tests measure text like the app does.
Future<void> loadAppFonts() async {
  const families = {
    'DM Mono': ['DMMono-Light.ttf', 'DMMono-Regular.ttf', 'DMMono-Medium.ttf'],
    'Bungee': ['Bungee-Regular.ttf'],
    'Manrope': ['Manrope-Variable.ttf'],
    'Inter': ['Inter-Variable.ttf'],
    'Fredoka': ['Fredoka-Variable.ttf'],
    'Noto Sans Symbols': ['NotoSansSymbols-Variable.ttf'],
    'Noto Sans Symbols 2': ['NotoSansSymbols2-Regular.ttf'],
    'Noto Emoji': ['NotoEmoji-Variable.ttf'],
  };
  for (final entry in families.entries) {
    final loader = FontLoader(entry.key);
    for (final file in entry.value) {
      loader.addFont(rootBundle.load('assets/fonts/$file'));
    }
    await loader.load();
  }
}
