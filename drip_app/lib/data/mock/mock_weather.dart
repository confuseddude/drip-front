/// Mock "today's weather" for the Home hero card. There's no weather API in
/// this app — this is seed data only, picked deterministically so the hero
/// doesn't flicker between rebuilds.
class MockWeather {
  const MockWeather({
    required this.tempF,
    required this.condition,
    required this.glyph,
    required this.advice,
  });

  final int tempF;
  final String condition;

  /// A simple text glyph (kept off real weather icon packs / network assets).
  final String glyph;

  /// Short line coordinating the condition with what to wear.
  final String advice;

  static const _presets = [
    MockWeather(
      tempF: 72,
      condition: 'Partly Cloudy',
      glyph: '⛅',
      advice: 'Light layers — a jacket you can tie around your waist.',
    ),
    MockWeather(
      tempF: 58,
      condition: 'Crisp & Clear',
      glyph: '☀︎',
      advice: 'Denim weather. Add a knit under your fit.',
    ),
    MockWeather(
      tempF: 66,
      condition: 'Light Rain',
      glyph: '☂',
      advice: 'Waterproof outer layer, save the suede for another day.',
    ),
    MockWeather(
      tempF: 81,
      condition: 'Sunny',
      glyph: '☼',
      advice: 'Breathable fabrics, go light on the layers today.',
    ),
  ];

  /// Deterministic "today" pick, stable across rebuilds.
  static MockWeather today() {
    final i = DateTime.now().day % _presets.length;
    return _presets[i];
  }
}
